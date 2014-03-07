require "spec_helper"

describe "CampusRosters" do
  it "should return a list of officially enrolled students for a course ccn" do
    user_id = rand(99999)
    official_student_id = rand(99999)
    official_student_login_id = rand(99999).to_s
    official_student_student_id = rand(99999).to_s
    ccn = rand(99999).to_s
    semester_slug = 'spring-2014'
    class_slug = 'mec_eng-132'

    CampusData.stub(:get_sections_from_ccns).with('2014', 'B', [ccn]).and_return(
        [
            {
                'course_title' => 'Dynamic Systems',
                'dept_name' => 'MEC ENG',
                'section_num'=>'001',
                'instruction_format'=>'LEC'
            }
        ]
    )
    CampusData.stub(:get_enrolled_students).with(ccn, '2014', 'B').and_return(
        [
            {
                'ldap_uid' => official_student_login_id,
                'enroll_status' => 'E',
                'student_id' => official_student_student_id,
                'first_name' => "Thurston",
                'last_name' => "Howell #{official_student_login_id}"
            }
        ]
    )
    model = CampusRosters.new(user_id, ccns: [ccn], semester_slug: semester_slug, class_slug: class_slug, primary_ccn: ccn)
    feed = model.get_feed
    feed[:campus_course][:id].should == 'mec_eng-132-spring-2014'
    feed[:sections].length.should == 1
    feed[:sections][0][:name].should == 'LEC 001'
    feed[:students].length.should == 1
    student = feed[:students][0]
    student[:id].should == official_student_login_id
    student[:student_id].should == official_student_student_id
    student[:first_name].blank?.should be_false
    student[:last_name].blank?.should be_false
    student[:sections].length.should == 1
    student[:profile_url].blank?.should be_false
  end

  it "should show official photo links for students who are not waitlisted in all sections" do
    user_id = rand(99999)
    enrolled_student_login_id = rand(99999).to_s
    enrolled_student_student_id = rand(99999).to_s
    waitlisted_student_login_id = rand(99999).to_s
    waitlisted_student_student_id = rand(99999).to_s
    ccns = []
    ccns[0] = rand(99999).to_s
    ccns[1] = rand(99999).to_s
    semester_slug = 'spring-2014'
    class_slug = 'mec_eng-132'

    CampusData.stub(:get_sections_from_ccns).with('2014', 'B', [ccns[0]]).and_return(
        [
            {
                'course_title' => 'Dynamic Systems',
                'dept_name' => 'MEC ENG',
                'section_num'=>'001',
                'instruction_format'=>'LEC'
            }
        ]
    )
    CampusData.stub(:get_sections_from_ccns).with('2014', 'B', [ccns[1]]).and_return(
        [
            {
                'course_title' => 'Dynamic Systems',
                'dept_name' => 'MEC ENG',
                'section_num'=>'002',
                'instruction_format'=>'LAB'
            }
        ]
    )
    CampusData.stub(:get_enrolled_students).with(ccns[0], '2014', 'B').and_return(
        [
            {
                'ldap_uid' => enrolled_student_login_id,
                'enroll_status' => 'E',
                'student_id' => enrolled_student_student_id
            },
            {
                'ldap_uid' => waitlisted_student_login_id,
                'enroll_status' => 'W',
                'student_id' => waitlisted_student_student_id
            }
        ]
    )
    CampusData.stub(:get_enrolled_students).with(ccns[1], '2014', 'B').and_return(
        [
            {
                'ldap_uid' => enrolled_student_login_id,
                'enroll_status' => 'E',
                'student_id' => enrolled_student_student_id
            },
            {
                'ldap_uid' => waitlisted_student_login_id,
                'enroll_status' => 'W',
                'student_id' => waitlisted_student_student_id
            }
        ]
    )
    model = CampusRosters.new(user_id, ccns: ccns, semester_slug: semester_slug, class_slug: class_slug, primary_ccn: ccns[0])
    feed = model.get_feed
    feed[:sections].length.should == 2
    feed[:students].length.should == 2
    feed[:students].index {|student| student[:id] == enrolled_student_login_id &&
        !student[:photo].end_with?(CampusRosters::PHOTO_UNAVAILABLE_FILENAME)
    }.should_not be_nil
    feed[:students].index {|student| student[:id] == waitlisted_student_login_id &&
        student[:photo].nil?
    }.should_not be_nil
  end

end
