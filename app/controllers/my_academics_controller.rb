class MyAcademicsController < ApplicationController

  before_filter :api_authenticate

  def get_feed
    render :json => MyAcademics::Merged.new(session[:user_id], :original_user_id => session[:original_user_id]).get_feed_as_json
  end

end
