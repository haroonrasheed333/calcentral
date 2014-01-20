require "spec_helper"
require "lib/canvas/canvas_authorization_helpers_spec"

describe CanvasController do

  before do
    session[:user_id] = "12345"
    session[:canvas_user_id] = "4321321"
    session[:canvas_course_id] = "767330"
    CanvasCourseUserProxy.stub(:is_course_admin?).and_return(true)
  end

  context "when serving course user profile information" do

    it_should_behave_like "an api endpoint" do
      before { subject.stub(:course_user_profile).and_raise(RuntimeError, "Something went wrong") }
      let(:make_request) { get :course_user_profile }
    end

    it_should_behave_like "a user authenticated controller" do
      let(:make_request) { get :course_user_profile }
    end

    it_should_behave_like "a canvas user authenticated controller" do
      let(:make_request) { get :course_user_profile }
    end

    it_should_behave_like "a canvas course user authenticated controller" do
      let(:make_request)                  { get :course_user_profile }
      let(:make_request_with_course_id)   { get :course_user_profile, canvas_course_id: "4123456" }
    end

    context "when session with canvas course user present" do

      it "returns course user details" do
        get :course_user_profile
        expect(response.status).to eq(200)
        response_json = JSON.parse(response.body)
        expect(response_json['course_user_profile']).to be_an_instance_of Hash
        course_user = response_json['course_user_profile']
        expect(course_user).to be_an_instance_of Hash
        expect(course_user['id']).to eq 4321321
        expect(course_user['name']).to eq "Michael Steven OWEN"
        expect(course_user['sis_user_id']).to eq "UID:105431"
        expect(course_user['sis_login_id']).to eq "105431"
        expect(course_user['login_id']).to eq "105431"
        expect(course_user['enrollments']).to be_an_instance_of Array
        expect(course_user['enrollments'].count).to eq 1
        expect(course_user['enrollments'][0]['course_id']).to eq 767330
        expect(course_user['enrollments'][0]['course_section_id']).to eq 1312468
        expect(course_user['enrollments'][0]['id']).to eq 20241907
        expect(course_user['enrollments'][0]['type']).to eq "StudentEnrollment"
        expect(course_user['enrollments'][0]['role']).to eq "StudentEnrollment"
      end
    end

  end

end
