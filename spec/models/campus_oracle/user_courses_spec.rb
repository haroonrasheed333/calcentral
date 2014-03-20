require "spec_helper"

describe CampusOracle::UserCourses do

  it "should be accessible if non-null user" do
    CampusOracle::UserCourses.access_granted?(nil).should be_false
    CampusOracle::UserCourses.access_granted?('211159').should be_true
    client = CampusOracle::UserCourses.new({user_id: '211159'})
    client.get_all_campus_courses.should_not be_nil
  end

  it "should return pre-populated test enrollments for all semesters", :if => Sakai::SakaiData.test_data? do
    Settings.sakai_proxy.academic_terms.stub(:student).and_return(nil)
    Settings.sakai_proxy.academic_terms.stub(:instructor).and_return(nil)
    client = CampusOracle::UserCourses.new({user_id: '300939'})
    courses = client.get_all_campus_courses
    courses.empty?.should be_false
    courses["2012-B"].length.should == 2
    courses["2013-D"].length.should == 2
    courses["2013-D"].each do |course|
      course[:id].blank?.should be_false
      course[:emitter].should == 'Campus'
      course[:name].blank?.should be_false
      course.should be_has_key(:cred_cd)
      ['Student', 'Instructor'].include?(course[:role]).should be_true
      sections = course[:sections]
      sections.length.should be > 0
      sections.each do |section|
        if section[:ccn] == "16171"
          section[:instruction_format].blank?.should be_false
          section[:section_number].blank?.should be_false
          section[:instructors].length.should == 1
          section[:instructors][0][:name].present?.should be_true
          section[:schedules][0][:schedule].should == "TuTh 2:00P-3:30P"
          section[:schedules][0][:building_name].should == "WHEELER"
        end
      end
    end
  end

  it 'includes nested sections for instructors', :if => Sakai::SakaiData.test_data? do
    client = CampusOracle::UserCourses.new({user_id: '238382'})
    courses = client.get_all_campus_courses
    sections = courses['2013-D'].select {|c| c[:dept] == 'BIOLOGY' && c[:catid] == '1A'}.first[:sections]
    expect(sections.size).to eq 3
    # One primary and two nested secondaries.
    expect(sections.collect{|s| s[:ccn]}).to eq ['07309', '07366', '07372']
  end

  it 'prefixes short CCNs with zeroes', :if => Sakai::SakaiData.test_data? do
    client = CampusOracle::UserCourses.new({user_id: '238382'})
    courses = client.get_selected_sections(2013, 'D', [7309])
    sections = courses['2013-D'].first[:sections]
    expect(sections.size).to eq 1
    expect(sections.first[:ccn]).to eq '07309'
  end

  it "should find waitlisted status in test enrollments", :if => Sakai::SakaiData.test_data? do
    Settings.sakai_proxy.academic_terms.stub(:student).and_return(nil)
    Settings.sakai_proxy.academic_terms.stub(:instructor).and_return(nil)
    client = CampusOracle::UserCourses.new({user_id: '300939'})
    courses = client.get_all_campus_courses
    courses["2015-B"].length.should == 1
    course = courses["2015-B"][0]
    course[:waitlist_position].should == '42'
    course[:enroll_limit].should == '5000'
  end

  it "should say that Tammi has student history", :if => Sakai::SakaiData.test_data? do
    client = CampusOracle::UserCourses.new({user_id: '300939'})
    client.has_student_history?.should be_true
  end

  it "should say that our fake teacher has instructor history", :if => Sakai::SakaiData.test_data? do
    client = CampusOracle::UserCourses.new({user_id: '238382'})
    client.has_instructor_history?.should be_true
  end

end
