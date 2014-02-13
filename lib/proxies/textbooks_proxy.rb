class TextbooksProxy < BaseProxy

  include ClassLogger

  APP_ID = "textbooks"

  def ul_to_dict(ul)
    books = []
    amazon_url = "http://www.amazon.com/gp/search?index=books&linkCode=qs&keywords="
    chegg_url = "http://www.chegg.com/search/"
    oskicat_url = "http://oskicat.berkeley.edu/search~S1/?searchtype=i&searcharg="
    googleplay_url = "https://play.google.com/store/search?q="

    if ul.length > 0
      book_list = ul.xpath('./li')

      book_list.each do |bl|
        isbn = bl.xpath('.//span[@id="materialISBN"]')[0].text.split(":")[1].strip

        book_detail = {
          :has_choices => bl.xpath('.//h3[@class="material-group-title choice-title"]').length > 0 || bl.xpath('.//div[@class="choice-list-heading-sub"]').length > 0,
          :title => bl.xpath('.//h3[@class="material-group-title"]')[0].text.split("\n")[0],
          :image => bl.xpath('.//span[@id="materialTitleImage"]/img/@src')[0].text,
          :isbn => isbn,
          :author => bl.xpath('.//span[@id="materialAuthor"]')[0].text.split(":")[1],
          :edition => bl.xpath('.//span[@id="materialEdition"]')[0].text.split(":")[1],
          :publisher => bl.xpath('.//span[@id="materialPublisher"]')[0].text.split(":")[1],
          :amazon_link => amazon_url + isbn,
          :chegg_link => chegg_url + isbn,
          :oskicat_link => oskicat_url + isbn,
          :googleplay_link => googleplay_url + isbn
        }
        books.push(book_detail)
      end
    end
    books
  end

  def has_choices(category_books)
    category_books.any? {|i| i[:has_choices] == true}
  end

  def get_term(slug)
    semester = slug.split('-')[0]
    year = slug.split('-')[1]

    case semester
    when 'fall'
      term = year + 'D'
    when 'spring'
      term = year + 'B'
    when 'summer'
      term = year + 'C'
    end
    term
  end

  def initialize(options = {})
    @ccns = options[:ccns]
    @slug = options[:slug]
    @term = get_term(@slug)
    @ccn = @ccns[0]
    super(Settings.textbooks_proxy, options)
  end

  def get
    ccn = @ccns[0]
    request("textbooks")
  end

  def request(vcr_cassette, params = {})
    self.class.fetch_from_cache("#{@ccn}-#{@slug}") do
      required_books = []
      recommended_books = []
      optional_books = []
      status_code = ''
      url = ''
      book_unavailable_error = ''
      safe_request("Currently, we can't reach the bookstore. Check again later for updates, or contact your instructor directly.") do
        @ccns.each do |ccn|
          path = "/webapp/wcs/stores/servlet/booklookServlet?bookstore_id-1=554&term_id-1=#{@term}&crn-1=#{ccn}"
          url = "#{Settings.textbooks_proxy.base_url}#{path}"
          logger.info "Fake = #@fake; Making request to #{url} on behalf of user #{@uid}; cache expiration #{self.class.expires_in}"
          response = FakeableProxy.wrap_request(APP_ID + "_" + vcr_cassette, @fake, {match_requests_on: [:method, :path]}) {
            HTTParty.get(
              url,
              timeout: Settings.application.outgoing_http_timeout
            )
          }

          if response.code >= 400
            raise Calcentral::ProxyError.new("Currently, we can't reach the bookstore. Check again later for updates, or contact your instructor directly.")
          end

          status_code = response.code
          text_books = Nokogiri::HTML(response.body)
          logger.debug "Remote server status #{response.code}; url = #{url}"
          text_books_items = text_books.xpath('//h2 | //ul')

          required_text_list = text_books_items.xpath('//h2[contains(text(), "Required")]/following::ul[1]')
          recommended_text_list = text_books_items.xpath('//h2[contains(text(), "Recommended")]/following::ul[1]')
          optional_text_list = text_books_items.xpath('//h2[contains(text(), "Optional")]/following::ul[1]')
          required_books.push(ul_to_dict(required_text_list))
          recommended_books.push(ul_to_dict(recommended_text_list))
          optional_books.push(ul_to_dict(optional_text_list))
          bookstore_error_section = text_books.xpath('//div[@id="efCourseErrorSection"]/h2')
          if bookstore_error_section.length > 0
            book_unavailable_error = bookstore_error_section[0].text.gsub('*', '').strip
          end
        end

        book_response = {
          :book_details => []
        }

        if !required_books.flatten.blank?
          book_response[:book_details].push({
            :type => "Required",
            :books => required_books.flatten,
            :has_choices => has_choices(required_books.flatten)
          })
        end

        if !recommended_books.flatten.blank?
          book_response[:book_details].push({
            :type => "Recommended",
            :books => recommended_books.flatten,
            :has_choices => has_choices(recommended_books.flatten)
          })
        end

        if !optional_books.flatten.blank?
          book_response[:book_details].push({
            :type => "Optional",
            :books => optional_books.flatten,
            :has_choices => has_choices(optional_books.flatten)
          })
        end

        book_response[:book_unavailable_error] = book_unavailable_error
        book_response[:has_books] = !(required_books.flatten.blank? && recommended_books.flatten.blank? && optional_books.flatten.blank?)
        {
          books: book_response,
          status_code: status_code
        }
      end
    end
  end
end
