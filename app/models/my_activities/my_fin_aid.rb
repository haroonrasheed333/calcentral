class MyActivities::MyFinAid
  include DatedFeed, ClassLogger
  extend Calcentral::Cacheable

  def self.append!(uid, activities)
    finaid_activities = get_activities_from_cache(uid)
    activities.concat(finaid_activities) if finaid_activities
  end

  private

  def self.get_activities_from_cache(uid)
    smart_fetch_from_cache({id: uid, user_message_on_exception: "Remote server unreachable", return_nil_on_generic_error: true}) do
      activities = []
      append_activities!(uid, activities)
      activities
    end
  end

  def self.append_activities!(uid, activities)
    finaid_proxy_current  = MyfinaidProxy.new({ user_id: uid, term_year: current_term_year })
    finaid_proxy_next     = MyfinaidProxy.new({ user_id: uid, term_year: next_term_year })

    return unless finaid_proxy_current.lookup_student_id.present?

    [finaid_proxy_current, finaid_proxy_next].each do |proxy|
      next unless feed = proxy.get.try(:[], :body)
      begin
        content = Nokogiri::XML(feed, &:strict)
      rescue Nokogiri::XML::SyntaxError
        next
      end

      next unless valid_xml_response?(uid, content)

      academic_year = term_year_to_s(proxy.term_year)

      append_diagnostics!(content.css("DiagnosticData Diagnostic"), academic_year, activities)
      append_documents!(content.css("TrackDocs Document"), academic_year, activities)
    end
  end

  def self.append_documents!(documents, academic_year, activities)
    documents.each do |document|
      title = document.css("Name").text.strip

      date = parsed_date(document.css("Date").text.strip)
      if date.present? && (date < cutoff_date)
        logger.info "Document is too old to be shown: #{date.inspect} < #{cutoff_date}"
        next
      end
      date = format_date(date) if date.present?

      summary = document.css("Supplemental Usage Content[Type='TXT']").text.strip
      url = document.css("Supplemental Usage Content[Type='URL']").text.strip
      url = "https://myfinaid.berkeley.edu" if url.blank?

      begin
        status = decode_status(date, document.css("Status").text.strip)
        next if status.nil?
      rescue ArgumentError
        logger.error "Unable to decode finAid status for document: #{document.inspect} date: #{date.inspect}, status: #{status.inspect}"
        next
      end

      result = {
        id: '',
        source: "Financial Aid",
        title: title,
        date: date,
        summary: summary,
        source_url: url,
        emitter: "Financial Aid",
        term_year: academic_year
      }

      if (status.values.none?)
        result[:type] = "alert"
        result[:status] = "Action required, missing document"
      elsif (status[:received] && !status[:reviewed])
        result[:type] = "financial"
        result[:status] = "No action required, document received not yet reviewed"
      elsif(status.values.all?)
        result[:type] = "message"
        result[:status] = "No action required, document reviewed and processed"
      end

      activities << result
    end
  end

  def self.append_diagnostics!(diagnostics, academic_year, activities)
    diagnostics.each do |diagnostic|
      next unless diagnostic.css("Categories Category[Name='CAT01']").text.try(:strip) == 'W'
      title = diagnostic.css("Message").text.strip
      url = diagnostic.css("Supplemental Usage Content[Type='URL']").text.strip
      url = "https://myfinaid.berkeley.edu" if url.blank?
      summary = diagnostic.css("Usage Content[Type='TXT']").text.strip
      category = diagnostic.attribute('Category').try('value')

      next unless (title.present? && summary.present?)

      activities <<  {
        id: '',
        title: title,
        summary: summary,
        source: "Financial Aid",
        type: diagnostic_type_from_category(category),
        date: "",
        source_url: url,
        emitter: "Financial Aid",
        term_year: academic_year
      }
    end
  end

  def self.diagnostic_type_from_category(category)
    if category == 'PKG'
      'info'
    elsif category == 'SUM'
      'financial'
    elsif ['MBA', 'DSB', 'SAP'].include? category
      'alert'
    else
      logger.warn("Unexpected diagnostic category: #{category}")
      'alert'
    end
  end

  def self.decode_status(date, status)
    if date.blank? && (status.blank? || status == 'Q')
      {
        received: false,
        reviewed: false,
      }
    elsif date.present? && status == 'N'
      {
        received: true,
        reviewed: false,
      }
    elsif date.present? && (status.blank? || status == "P")
      {
        received: true,
        reviewed: true,
      }
    elsif ['W'].include? status
      logger.info("Ignore documents with \"#{status}\" status")
      nil
    else
      raise ArgumentError, "Cannot decode date: #{date} status: #{status}"
    end
  end

  def self.current_term_year
    # to-do: revise this logic with the team
    return Settings.myfinaid_proxy.test_term_year if Settings.myfinaid_proxy.fake
    year      = Time.now.year
    term_year = (Time.now.month.between?(1, 8)) ? year : year + 1
    "#{term_year}"
  end

  def self.cutoff_date
    @cutoff_date ||= (Time.zone.now - 1.year)
  end

  def self.next_term_year
    "#{current_term_year.to_i + 1}"
  end

  def self.parsed_date(date_string='')
    Date.parse(date_string).to_time_in_current_zone.to_datetime rescue ""
  end

  def self.term_year_to_s(term_year)
    "#{term_year.to_i-1}-#{term_year}"
  end

  def self.valid_xml_response?(uid, xmldoc)
    code = xmldoc.css('Response Code').text.strip
    message = xmldoc.css('Response Message').text.strip
    return true if code == '0000'
    logger.warn("Feed not available for UID (#{uid}). Code: #{code}, Message: #{message}")
    false
  end

end
