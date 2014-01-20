require "spec_helper"

describe "MyFinancials" do

  let!(:oski_uid) { "61889" }
  let!(:fake_financials_proxy) { FinancialsProxy.new({user_id: oski_uid, fake: true}) }
  before(:each) { FinancialsProxy.stub(:new).and_return(fake_financials_proxy) }

  context "happy path" do
    subject { MyFinancials.new(oski_uid).get_feed }
    it { should_not be_nil }
    its(["summary"]) { should_not be_nil }
    its(["current_term"]) { should == Settings.sakai_proxy.current_terms.first }
  end

  context "it should not explode on a proxy error state" do
    before(:each) { fake_financials_proxy.stub(:get).and_return(
      {
        body: "an error message",
        status_code: 500
      }
    ) }
    subject { MyFinancials.new(oski_uid).get_feed }
    it { subject.length.should == 4 }
    its([:body]) { should == "an error message"}
    its([:status_code]) { should == 500 }
  end

  context "it should not explode on a null proxy response" do
    before(:each) { fake_financials_proxy.stub(:get).and_return(nil) }
    subject { MyFinancials.new(oski_uid).get_feed }
    it { subject.length.should == 2 }
  end

end
