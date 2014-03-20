class CanvasRostersController < RostersController
  include ClassLogger

  # GET /api/academics/rosters/canvas/:canvas_course_id
  def get_feed
    if (model = valid_model(params[:canvas_course_id], "Canvas"))
      if (feed = model.get_feed)
        render :json => feed.to_json
      else
        render :nothing => true, :status => 401
      end
    else
      render :nothing => true, :status => 401
    end
  end

end
