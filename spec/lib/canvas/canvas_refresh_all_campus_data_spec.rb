require "spec_helper"

describe CanvasRefreshAllCampusData do

  let(:current_sis_term_ids)                    { ["TERM:2013-D", "TERM:2014-B"] }
  subject { CanvasRefreshAllCampusData.new('incremental') }

  before do
    CanvasProxy.stub(:current_sis_term_ids).and_return(current_sis_term_ids)
    frozen_moment_in_time = Time.at(1388563200).to_datetime
    DateTime.stub(:now).and_return(frozen_moment_in_time)
  end

	it "establishes the csv import files" do
    expect(subject.users_csv_filename).to be_an_instance_of String
    expect(subject.users_csv_filename).to eq "tmp/canvas/canvas-2014-01-01-users-incremental.csv"
    expect(subject.term_to_memberships_csv_filename).to be_an_instance_of Hash
    expect(subject.term_to_memberships_csv_filename['TERM:2013-D']).to eq "tmp/canvas/canvas-2014-01-01-TERM_2013-D-enrollments-incremental.csv"
    expect(subject.term_to_memberships_csv_filename['TERM:2014-B']).to eq "tmp/canvas/canvas-2014-01-01-TERM_2014-B-enrollments-incremental.csv"
  end

  it "makes calls to each step of refresh in proper order" do
    subject.should_receive(:make_csv_files).ordered.and_return(true)
    subject.should_receive(:import_csv_files).ordered.and_return(true)
    subject.run
  end

  context "when making csv files" do
    before do
      CanvasMaintainUsers.any_instance.stub(:refresh_existing_user_accounts).and_return(nil)
      CanvasIncrementalEnrollments.any_instance.stub(:refresh_existing_term_sections).and_return(nil)
    end

    it "should send call to populate incremental update csv for users" do
      CanvasMaintainUsers.any_instance.should_receive(:refresh_existing_user_accounts).once.and_return(nil)
      subject.make_csv_files
    end

    it "should send call to populate each terms incremental update csv for enrollments" do
      CanvasIncrementalEnrollments.any_instance.should_receive(:refresh_existing_term_sections).twice.and_return(nil)
      subject.make_csv_files
    end
  end
end
