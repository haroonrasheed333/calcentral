class SessionsController < ApplicationController
  include ActiveRecordHelper

  def lookup
    auth = request.env["omniauth.auth"]
    continue_login_success auth['uid']
  end

  def basic_lookup
    uid = authenticate_with_http_basic do |uid, password|
      uid if password == Settings.developer_auth.password
    end

    if uid
      continue_login_success uid
    else
      failure
    end
  end

  def act_as
    return redirect_to root_path unless valid_params?(current_user, params[:uid])
    Rails.logger.warn "ACT-AS: User #{session[:user_id]} acting as #{params[:uid]} begin"
    session[:original_user_id] = session[:user_id] unless session[:original_user_id]
    session[:user_id] = params[:uid]

    render :nothing => true, :status => 204
  end

  def stop_act_as
    return redirect_to root_path unless session[:user_id] && session[:original_user_id]

    #To avoid any potential stale data issues, we might have to be aggressive with cache invalidation.
    pseudo_user = Calcentral::PSEUDO_USER_PREFIX + session[:user_id]
    [pseudo_user, session[:user_id]].each do |cache_key|
      Calcentral::USER_CACHE_EXPIRATION.notify cache_key
    end
    Rails.logger.warn "ACT-AS: User #{session[:original_user_id]} acting as #{session[:user_id]} ends"
    session[:user_id] = session[:original_user_id]
    session[:original_user_id] = nil

    render :nothing => true, :status => 204
  end

  def destroy
    begin
      reset_session
    ensure
      ActiveRecord::Base.clear_active_connections!
    end
    render :json => {
      :redirect_url => "#{Settings.cas_logout_url}?url=#{CGI.escape(request.protocol + request.host_with_port)}"
    }.to_json
  end

  def failure
    params ||= {}
    params[:message] ||= ''
    redirect_to root_path, :status => 401, :alert => "Authentication error: #{params[:message].humanize}"
  end

  private

  def smart_success_path
    # the :url parameter is returned by the CAS auth server
    (params[:url].present?) ? params[:url] : url_for_path('/dashboard')
  end

  def continue_login_success(uid)
    # Force a new CSRF token to be generated on login.
    # http://homakov.blogspot.com.es/2013/06/cookie-forcing-protection-made-easy.html
    session.try(:delete, :_csrf_token)
    if (Integer(uid, 10) rescue nil).nil?
      Rails.logger.warn "FAILED login with CAS UID: #{uid}"
      redirect_to url_for_path('/uid_error')
    else
      session[:user_id] = uid
      redirect_to smart_success_path, :notice => "Signed in!"
    end
  end

  def valid_params?(current_user, act_as_uid)
    if current_user.blank? || act_as_uid.blank?
      Rails.logger.warn "ACT-AS: User #{current_user.uid} FAILED to login to #{act_as_uid}, either cannot be blank!"
      return false
    end

    # Ensure that uids are numeric
    begin
      [current_user.uid, act_as_uid].each do |param|
        Integer(param, 10)
      end
    rescue ArgumentError
        Rails.logger.warn "ACT-AS: User #{current_user.uid} FAILED to login to #{act_as_uid}, values must be integers"
        return false
    end

    # Make sure someone has logged in already before assuming their identify
    # Also useful to enforce in the testing scenario due to the redirect to the settings page.
    never_logged_in_before = true
    use_pooled_connection {
      never_logged_in_before = User::Data.where(:uid => act_as_uid).first.blank?
    }
    if never_logged_in_before && Settings.application.layer == "production"
      Rails.logger.warn "ACT-AS: User #{current_user.uid} FAILS to login to #{act_as_uid}, #{act_as_uid} hasn't logged in before."
      return false
    end

    if session[:original_user_id]
      auth_user_id = session[:original_user_id]
    else
      auth_user_id = current_user.uid
    end

    policy = User::Auth.get(auth_user_id).policy
    policy.can_act_as?
  end

end
