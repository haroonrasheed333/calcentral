require "spec_helper"

describe MyActivities::MyFinAid do
  let!(:oski_uid) { "61889" }
  let!(:fake_oski_finaid){ MyfinaidProxy.new({user_id: oski_uid, fake: true}) }
  let!(:non_student_uid) { '212377' }
  let(:documented_types) { %w(alert financial message) }

  it { described_class.should respond_to(:append!) }

  context "non 2xx states" do
    before(:each) { @activities = ["some activity"] }

    context "non-student finaid" do
      subject { MyActivities::MyFinAid.append!(non_student_uid, @activities ||= []); @activities}

      it { should eq(["some activity"]) }
    end

    context "dead remote proxy (5xx errors)" do
      before(:each) { stub_request(:any, /#{Regexp.quote(Settings.myfinaid_proxy.base_url)}.*/).to_raise(Faraday::Error::ConnectionFailed) }
      after(:each) { WebMock.reset! }

      subject { MyActivities::MyFinAid.append!(oski_uid, @activities ||= []); @activities}

      it { should eq(["some activity"]) }
    end

    context "4xx errors on remote proxy" do
      before(:each) { stub_request(:any, /#{Regexp.quote(Settings.myfinaid_proxy.base_url)}.*/).to_return(:status => 403) }
      after(:each) { WebMock.reset! }

      subject { MyActivities::MyFinAid.append!(oski_uid, @activities ||= []); @activities}

      it { should eq(["some activity"]) }
    end
  end

  context "2xx states" do
    before(:each) { MyfinaidProxy.stub(:new).and_return(fake_oski_finaid) }

    subject do
      MyActivities::MyFinAid.append!(oski_uid, @activities ||= [])
      @activities
    end

    it { should_not be_blank }
    it { subject.length.should eq(13) }
    it { subject.each { |entry| documented_types.should be_include(entry[:type]) } }
    it { subject.each { |entry| entry[:title].should be_present } }
    it { subject.each { |entry| entry[:source_url].should be_present } }
    it { subject.each { |entry| entry[:source].should eq("Financial Aid") } }

    context "alert types" do
      subject do
        MyActivities::MyFinAid.append!(oski_uid, @activities ||= [])
        @activities.select { |entry| entry[:type] == "alert" }
      end

      it { subject.length.should eq(10) }
      it { subject.each { |entry| entry[:date].should be_blank } }
    end

    context "financial types" do
      subject do
        MyActivities::MyFinAid.append!(oski_uid, @activities ||= [])
        @activities.select { |entry| entry[:type] == "financial" }
      end

      it { subject.length.should eq(1) }
      it { subject.each { |entry| entry[:title].should be_present } }
    end

    context "message types" do
      subject do
        MyActivities::MyFinAid.append!(oski_uid, @activities ||= [])
        @activities.select { |entry| entry[:type] == "message" }
      end

      it { subject.length.should eq(2) }
      it { subject.each { |entry| entry[:title].should be_present } }
    end

  end

end