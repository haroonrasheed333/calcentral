class IsUpdatedController < ApplicationController

  def list
    if session[:user_id]
      LiveUpdatesWarmer.warmup_request session[:user_id]
      whiteboard = Cache::FeedUpdateWhiteboard.get_whiteboard session[:user_id]
      render :json => whiteboard.to_json, :status => 200
    else
      render :nothing => true, :status => 401
    end
  end

end
