module Canvas
  class UserActivityStream < Proxy

    def user_activity
      request("users/self/activity_stream?as_user_id=sis_login_id:#{@uid}", "_user_activity")
    end

  end
end
