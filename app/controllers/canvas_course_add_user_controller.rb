class CanvasCourseAddUserController < ApplicationController

  include Canvas::AuthorizationHelpers
  before_filter :authenticate_cas_user!
  before_filter :authenticate_canvas_user!
  before_filter :authenticate_canvas_course_user!
  before_filter :authorize_canvas_course_admin!
  rescue_from Errors::ClientError, with: :handle_client_error
  rescue_from StandardError, with: :handle_api_exception

  # GET /api/academics/canvas/course_add_user/search_users.json
  def search_users
    raise Errors::BadRequestError, "Parameter 'search_text' is blank" if params['search_text'].blank?
    raise Errors::BadRequestError, "Parameter 'search_type' is invalid" unless Canvas::CourseAddUser::SEARCH_TYPES.include?(params['search_type'])
    users_found = Canvas::CourseAddUser.search_users(params['search_text'], params['search_type'])
    render json: { users: users_found }.to_json
  end

  # GET /api/academics/canvas/course_add_user/course_sections.json
  def course_sections
    sections_list = Canvas::CourseAddUser.course_sections_list(@canvas_course_id)
    render json: { course_sections: sections_list }.to_json
  end

  # POST /api/academics/canvas/course_add_user/add_user.json
  def add_user
    Canvas::CourseAddUser.add_user_to_course_section(params[:ldap_user_id], params[:role_id], params[:section_id])
    user_added = { :ldap_user_id => params[:ldap_user_id], :role_id => params[:role_id], :section_id => params[:section_id] }
    render json: { user_added: user_added }.to_json
  end

end
