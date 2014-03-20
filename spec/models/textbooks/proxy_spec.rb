require "spec_helper"

describe Textbooks::Proxy do

  it "should get real textbook feed for valid ccns and slug", :testext => true do
    @ccns = ["41575"]
    @slug = "spring-2014"
    proxy = Textbooks::Proxy.new({:ccns => @ccns, :slug => @slug, :fake => false})
    proxy_response = proxy.get
    proxy_response[:status_code].should_not be_nil
    if proxy_response[:status_code] == 200
      feed = proxy_response[:books]
      feed.should_not be_nil
      feed[:hasBooks].should be_true
      expect(feed[:bookDetails][0][:books][0][:title]).to eq 'Observing the User Experience'
      feed[:bookDetails][0][:hasChoices].should be_false
    end
  end

  it "should return false for hasBooks when either ccn or slug is invalid", :testext => true do
    @ccns = ['20764']
    @slug = 'fall-2011'
    proxy = Textbooks::Proxy.new({:ccns => @ccns, :slug => @slug, :fake => false})
    proxy_response = proxy.get
    proxy_response[:status_code].should_not be_nil
    if proxy_response[:status_code] == 200
      feed = proxy_response
      feed.should_not be_nil
      feed[:hasBooks].should be_false
    end
  end

  it "should return true for hasChoices when there are choices for a book", :testext => true do
    @ccns = ['73899']
    @slug = 'spring-2014'
    proxy = Textbooks::Proxy.new({:ccns => @ccns, :slug => @slug, :fake => false})
    proxy_response = proxy.get
    proxy_response[:status_code].should_not be_nil
    if proxy_response[:status_code] == 200
      feed = proxy_response[:books]
      feed.should_not be_nil
      feed[:hasBooks].should be_true
      feed[:bookDetails][0][:hasChoices].should be_true
    end
  end

  it "should return a friendly error message when a course can't be found", :testext => true do
    @ccns = ["09259"]
    @slug = "spring-2014"
    proxy = Textbooks::Proxy.new({:ccns => @ccns, :slug => @slug, :fake => false})
    proxy_response = proxy.get
    proxy_response[:status_code].should_not be_nil
    if proxy_response[:status_code] == 200
      feed = proxy_response[:books]
      feed.should_not be_nil
      expect(feed[:bookUnavailableError]).to eq 'Textbook information for this course could not be found.'
    end
  end

  it "should get data as json" do
    Rails.cache.should_receive(:write)
    @ccns = ["41575"]
    @slug = "spring-2014"
    proxy = Textbooks::Proxy.new({:ccns => @ccns, :slug => @slug, :fake => false})
    proxy_response = proxy.get_as_json
    proxy_response.should_not be_nil
    parsed_response = JSON.parse(proxy_response)
    parsed_response.should_not be_nil
    if proxy_response["status_code"] == 200
      feed = proxy_response["books"]
      feed.should_not be_nil
    end
  end

  it "should return a friendlier error message when a future term can't be found", :testext => true do
    @ccns = ["09259"]
    @slug = "spring-2074"
    proxy = Textbooks::Proxy.new({:ccns => @ccns, :slug => @slug, :fake => false})
    proxy_response = proxy.get
    proxy_response[:status_code].should_not be_nil
    if proxy_response[:status_code] == 200
      feed = proxy_response[:books]
      feed.should_not be_nil
      expect(feed[:bookUnavailableError]).to eq 'Textbook information for this term could not be found.'
    end
  end

end
