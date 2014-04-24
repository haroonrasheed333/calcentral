require "spec_helper"
require "set"

describe Canvas::CoursePolicy do
  let(:user_id)             { Settings.canvas_proxy.test_user_id }
  let(:user)                { User::Auth.get(user_id) }
  let(:super_user)          { User::Auth.new(uid: user_id, is_superuser: true, active: true) }
  let(:canvas_course_id)    { 1121 }
  let(:course)              { Canvas::Course.new(:user_id => user.uid, :canvas_course_id => canvas_course_id) }
  let(:course_user_hash) do
    {
      "id" => 3323890,
      "name" => "Stu Testb",
      "sortable_name" => "Testb, Stu",
      "short_name" => "Stu Testb",
      "sis_user_id" => "300846",
      "sis_login_id" => "300846",
      "sis_import_id" => 6132026,
      "login_id" => "300846",
      "enrollments"=>[
        {
          "id"=>19986607,
          "root_account_id"=>90242,
          "user_id"=>3323890,
          "associated_user_id"=>nil,
          "course_id"=>1121,
          "course_section_id"=>1237014,
          "sis_import_id"=>nil,
          "enrollment_state"=>"active",
          "type"=>"StudentEnrollment",
          "role"=>"StudentEnrollment",
          "limit_privileges_to_course_section"=>false,
          "html_url"=>"https://berkeley.instructure.com/courses/1121/users/3323890",
          "start_at"=>nil,
          "end_at"=>nil,
          "last_activity_at"=>"2014-02-21T19:12:10Z",
          "updated_at"=>"2014-01-31T00:09:55Z",
          "created_at"=>"2013-08-22T21:28:15Z",
        }
      ]
    }
  end
  let(:course_teacher_hash)   { course_user_hash.merge({'enrollments' => [{'type' => 'TeacherEnrollment', 'role' => 'TeacherEnrollment'}]}) }
  let(:course_ta_hash)        { course_user_hash.merge({'enrollments' => [{'type' => 'TaEnrollment', 'role' => 'TaEnrollment'}]}) }
  let(:course_designer_hash)  { course_user_hash.merge({'enrollments' => [{'type' => 'DesignerEnrollment', 'role' => 'DesignerEnrollment'}]}) }
  let(:invariable_course_user_hash) { course_user_hash }
  subject { Canvas::CoursePolicy.new(user, course) }
  before  { Canvas::CourseUser.any_instance.stub(:course_user).and_return(invariable_course_user_hash) }

  shared_examples "a canvas user requirement" do
    context "when no canvas user found for current user" do
      before { Canvas::UserProfile.any_instance.stub(:user_profile).and_return(nil) }
      it "returns false" do
        expect(authorization_method).to be_false
      end
    end
  end

  describe "#can_add_users?" do
    it_should_behave_like "a canvas user requirement" do
      let(:authorization_method) { subject.can_add_users? }
    end

    context "when user is a primary account admin" do
      before do
        canvas_admins = double()
        canvas_admins.stub(:admin_user?).and_return(true)
        Canvas::Admins.stub(:new).and_return(canvas_admins)
      end
      it "should return true" do
        expect(subject.can_add_users?).to be_true
      end
    end

    context "when user is a course admin" do
      let(:invariable_course_user_hash) { course_teacher_hash }
      it "should return true" do
        expect(subject.can_add_users?).to be_true
      end
    end

    context "when user is only a student" do
      it "should return false" do
        expect(subject.can_add_users?).to be_false
      end
    end
  end

  describe "#is_canvas_user?" do
    it_should_behave_like "a canvas user requirement" do
      let(:authorization_method) { subject.is_canvas_user? }
    end

    context "if canvas user does exist" do
      it "returns true" do
        expect(subject.is_canvas_course_user?).to be_true
      end
    end
  end

  describe "#is_canvas_account_admin?" do
    it "returns true when user is a canvas root account administrator" do
      canvas_admins = double()
      canvas_admins.stub(:admin_user?).and_return(true)
      Canvas::Admins.stub(:new).and_return(canvas_admins)
      expect(subject.is_canvas_account_admin?).to be_true
    end

    it "returns false when user is not a canvas root account administrator" do
      expect(subject.is_canvas_account_admin?).to be_false
    end
  end

  describe "#is_canvas_course_user?" do

    context "if user is not a member of the course" do
      before { Canvas::CourseUser.any_instance.stub(:course_user).and_return(nil) }
      it "returns false" do
        expect(subject.is_canvas_course_user?).to be_false
      end
    end

    context "if user is a member of the course" do
      it "returns true" do
        expect(subject.is_canvas_course_user?).to be_true
      end
    end
  end

  describe "#is_canvas_course_admin" do
    context "if user is a student within the course" do
      it "returns false" do
        expect(subject.is_canvas_course_admin?).to be_false
      end
    end

    context "if user is a teacher within the course" do
      let(:invariable_course_user_hash) { course_teacher_hash }
      it "returns true" do
        expect(subject.is_canvas_course_admin?).to be_true
      end
    end

    context "if user is a teachers assistant within the course" do
      let(:invariable_course_user_hash) { course_ta_hash }
      it "returns true" do
        expect(subject.is_canvas_course_admin?).to be_true
      end
    end

    context "if user is a designer within the course" do
      let(:invariable_course_user_hash) { course_designer_hash }
      it "returns true" do
        expect(subject.is_canvas_course_admin?).to be_true
      end
    end
  end

end
