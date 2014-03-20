require "spec_helper"
require "models/canvas/authorization_helpers_spec"

describe CanvasCourseAddUserController do

  let(:course_user_hash) do
    {
      'id' => 4321321, 'name' => "Michael Steven OWEN", 'sis_user_id' => "UID:105431", 'sis_login_id' => "105431", 'login_id' => "105431",
      'enrollments' => [{'id' => 20241907, 'course_id' => 767330, 'course_section_id' => 1312468, 'type' => 'TeacherEnrollment', 'role' => 'TeacherEnrollment'}]
    }
  end

  let(:users_found) do
    [
      { 'first_name' => 'Felix', 'last_name' => 'Gracia', 'email_address' => 'fgracia@example.edu', 'student_id' => '1097826', 'ldap_uid' => '12890', 'affiliations' => 'EMPLOYEE-TYPE-STAFF,STUDENT-STATUS-EXPIRED' },
      { 'first_name' => 'Brian', 'last_name' => 'Spires', 'email_address' => 'brianlspires@example.edu', 'student_id' => '1039872', 'ldap_uid' => '10054', 'affiliations' => 'EMPLOYEE-STATUS-EXPIRED,STUDENT-STATUS-EXPIRED' },
      { 'first_name' => 'Maria', 'last_name' => 'Patterson', 'email_address' => 'mjpatterson@example.edu', 'student_id' => '1002331', 'ldap_uid' => '4883', 'affiliations' => 'STUDENT-TYPE-REGISTERED,EMPLOYEE-TYPE-ACADEMIC' },
    ]
  end

  let(:course_sections_list) do
    [
      {"id" => "202184", "name" => "Section One Name"},
      {"id" => "1237009", "name" => "Section Two Name"}
    ]
  end

  before do
    session[:user_id] = "12345"
    session[:canvas_user_id] = "4321321"
    session[:canvas_course_id] = "767330"
    Canvas::CourseUser.stub(:is_course_admin?).and_return(true)
    Canvas::CourseAddUser.stub(:course_sections_list).and_return(course_sections_list)
  end

  context "when performing user search" do
    before do
      Canvas::CourseAddUser.stub(:search_users).with('John Doe', 'name').and_return(users_found)
    end

    it_should_behave_like "an api endpoint" do
      before { subject.stub(:search_users).and_raise(RuntimeError, "Something went wrong") }
      let(:make_request) { get :search_users, search_text: "John Doe", search_type: "name" }
    end

    it_should_behave_like "a user authenticated controller" do
      let(:make_request) { get :search_users, search_text: "John Doe", search_type: "name" }
    end

    it_should_behave_like "a canvas user authenticated controller" do
      let(:make_request) { get :search_users, search_text: "John Doe", search_type: "name" }
    end

    it_should_behave_like "a canvas course user authenticated controller" do
      let(:make_request)                { get :search_users, search_text: "John Doe", search_type: "name" }
      let(:make_request_with_course_id) { get :search_users, search_text: "John Doe", search_type: "name", canvas_course_id: "4123456" }
    end

    it_should_behave_like "a canvas course admin authorized controller" do
      let(:make_request) { get :search_users, search_text: "John Doe", search_type: "name" }
    end

    it "returns user search results" do
      Canvas::CourseAddUser.should_receive(:search_users).with('John Doe', 'name').and_return(users_found)
      get :search_users, search_text: "John Doe", search_type: "name"
      expect(response.status).to eq(200)
      json_response = JSON.parse(response.body)
      expect(json_response['users']).to be_an_instance_of Array
      expect(json_response['users'].count).to eq 3
      json_response['users'].each do |user|
        expect(user).to be_an_instance_of Hash
      end
    end
  end

  context "when obtaining list of course sections" do

    it_should_behave_like "an api endpoint" do
      before { subject.stub(:course_sections).and_raise(RuntimeError, "Something went wrong") }
      let(:make_request) { get :course_sections }
    end

    it_should_behave_like "a user authenticated controller" do
      let(:make_request) { get :course_sections }
    end

    it_should_behave_like "a canvas user authenticated controller" do
      let(:make_request) { get :course_sections }
    end

    it_should_behave_like "a canvas course user authenticated controller" do
      let(:make_request)                { get :course_sections }
      let(:make_request_with_course_id) { get :course_sections, canvas_course_id: "4123456" }
    end

    it_should_behave_like "a canvas course admin authorized controller" do
      let(:make_request) { get :course_sections }
    end

    it "returns sections for search" do
      get :course_sections
      expect(response.status).to eq(200)
      json_response = JSON.parse(response.body)
      expect(json_response['course_sections']).to be_an_instance_of Array
      expect(json_response['course_sections'].count).to eq 2
      expect(json_response['course_sections'][0]).to be_an_instance_of Hash
      expect(json_response['course_sections'][0]['id']).to eq "202184"
      expect(json_response['course_sections'][0]['name']).to eq "Section One Name"
      expect(json_response['course_sections'][1]).to be_an_instance_of Hash
      expect(json_response['course_sections'][1]['id']).to eq "1237009"
      expect(json_response['course_sections'][1]['name']).to eq "Section Two Name"
    end
  end

  context "when adding user to course" do
    before { Canvas::CourseAddUser.stub(:add_user_to_course_section).and_return(true) }

    it_should_behave_like "an api endpoint" do
      before { subject.stub(:add_user).and_raise(RuntimeError, "Something went wrong") }
      let(:make_request) { post :add_user, ldap_user_id: "260506", role_id: "StudentEnrollment", section_id: 864215 }
    end

    it_should_behave_like "a user authenticated controller" do
      let(:make_request) { post :add_user, ldap_user_id: "260506", role_id: "StudentEnrollment", section_id: 864215 }
    end

    it_should_behave_like "a canvas user authenticated controller" do
      let(:make_request) { post :add_user, ldap_user_id: "260506", role_id: "StudentEnrollment", section_id: 864215 }
    end

    it_should_behave_like "a canvas course user authenticated controller" do
      let(:make_request)                { post :add_user, ldap_user_id: "260506", role_id: "StudentEnrollment", section_id: 864215 }
      let(:make_request_with_course_id) { post :add_user, ldap_user_id: "260506", role_id: "StudentEnrollment", section_id: 864215, canvas_course_id: "4123456" }
    end

    it_should_behave_like "a canvas course admin authorized controller" do
      let(:make_request) { post :add_user, ldap_user_id: "260506", role_id: "StudentEnrollment", section_id: 864215 }
    end

    it "adds user to course section" do
      post :add_user, ldap_user_id: "260506", role_id: "StudentEnrollment", section_id: "864215"
      expect(response.status).to eq(200)
      json_response = JSON.parse(response.body)
      expect(json_response['user_added']).to be_an_instance_of Hash
      expect(json_response['user_added']['ldap_user_id']).to eq "260506"
      expect(json_response['user_added']['role_id']).to eq "StudentEnrollment"
      expect(json_response['user_added']['section_id']).to eq "864215"
    end
  end

end
