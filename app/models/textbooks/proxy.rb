module Textbooks
  class Proxy < BaseProxy

    include ClassLogger

    APP_ID = "textbooks"

    def google_book(isbn)
      google_book_url = "https://www.googleapis.com/books/v1/volumes?q=isbn:" + isbn
      google_response = ""
      response = HTTParty.get(
        google_book_url,
        timeout: Settings.application.outgoing_http_timeout
      )

      if response["totalItems"] > 0
        google_response = response["items"][0]["volumeInfo"]["infoLink"]
      end

      return google_response
    end

    def ul_to_dict(ul)
      books = []
      amazon_url = "http://www.amazon.com/gp/search?index=books&linkCode=qs&keywords="
      chegg_url = "http://www.chegg.com/search/"
      oskicat_url = "http://oskicat.berkeley.edu/search~S1/?searchtype=i&searcharg="

      if ul.length > 0
        book_list = ul.xpath('./li')

        book_list.each do |bl|
          isbn = bl.xpath('.//span[@id="materialISBN"]')[0].text.split(":")[1].strip

          book_detail = {
            :hasChoices => bl.xpath('.//h3[@class="material-group-title choice-title"]').length > 0 || bl.xpath('.//div[@class="choice-list-heading-sub"]').length > 0,
            :title => bl.xpath('.//h3[@class="material-group-title"]')[0].text.split("\n")[0],
            :image => bl.xpath('.//span[@id="materialTitleImage"]/img/@src')[0].text,
            :isbn => isbn,
            :author => bl.xpath('.//span[@id="materialAuthor"]')[0].text.split(":")[1],
            :edition => bl.xpath('.//span[@id="materialEdition"]')[0].text.split(":")[1],
            :publisher => bl.xpath('.//span[@id="materialPublisher"]')[0].text.split(":")[1],
            :amazonLink => amazon_url + isbn,
            :cheggLink => chegg_url + isbn,
            :oskicatLink => oskicat_url + isbn,
            :googlebookLink => google_book(isbn)
          }
          books.push(book_detail)
        end
      end
      books
    end

    def has_choices(category_books)
      category_books.any? { |i| i[:hasChoices] == true }
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

    def get_as_json
      self.class.smart_fetch_from_cache(
        {id: "#{@ccn}-#{@slug}",
         user_message_on_exception: "Currently, we can't reach the bookstore. Check again later for updates, or contact your instructor directly.",
         jsonify: true}) do
        get
      end
    end

    def get
      request_internal('Textbooks')
    end

    def request_internal(vcr_cassette)
      return {} unless Settings.features.textbooks
      required_books = []
      recommended_books = []
      optional_books = []
      status_code = ''
      url = ''
      bookstore_error_text = ''

      @ccns.each do |ccn|
        path = "/webapp/wcs/stores/servlet/booklookServlet?bookstore_id-1=554&term_id-1=#{@term}&crn-1=#{ccn}"
        url = "#{Settings.textbooks_proxy.base_url}#{path}"
        logger.info "Fake = #@fake; Making request to #{url}; cache expiration #{self.class.expires_in}"
        response = FakeableProxy.wrap_request(APP_ID + "_" + vcr_cassette, @fake, {match_requests_on: [:method, :path]}) {
          HTTParty.get(
            url,
            timeout: Settings.application.outgoing_http_timeout
          )
        }

        if response.code >= 400
          raise Errors::ProxyError.new("Currently, we can't reach the bookstore. Check again later for updates, or contact your instructor directly.")
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
          bookstore_error_text = bookstore_error_section[0].text.gsub('*', '').strip
        end
      end

      book_unavailable_error =
        case bookstore_error_text
          when /No Information Received For This Course./
            'Currently, there is no textbook information for this course. Check again later for updates, or contact your instructor directly.'
          when /We are unable to find the specified course./
            'Textbook information for this course could not be found.'
          when /No Store Supplied Material/
            'No materials for this course are supplied by the Cal Student Store. Contact the instructor regarding any custom materials.'
          when /No Books Required For This Course./
            'There are no required books for this course.'
          when /We are unable to find the requested term/
            'Textbook information for this term could not be found.'
          else
            bookstore_error_text
        end

      book_response = {
        :bookDetails => []
      }

      if !required_books.flatten.blank?
        book_response[:bookDetails].push({
                                            :type => "Required",
                                            :books => required_books.flatten,
                                            :hasChoices => has_choices(required_books.flatten)
                                          })
      end

      if !recommended_books.flatten.blank?
        book_response[:bookDetails].push({
                                            :type => "Recommended",
                                            :books => recommended_books.flatten,
                                            :hasChoices => has_choices(recommended_books.flatten)
                                          })
      end

      if !optional_books.flatten.blank?
        book_response[:bookDetails].push({
                                            :type => "Optional",
                                            :books => optional_books.flatten,
                                            :hasChoices => has_choices(optional_books.flatten)
                                          })
      end

      book_response[:bookUnavailableError] = book_unavailable_error
      book_response[:hasBooks] = !(required_books.flatten.blank? && recommended_books.flatten.blank? && optional_books.flatten.blank?)
      {
        books: book_response,
        status_code: status_code
      }

    end

  end
end
