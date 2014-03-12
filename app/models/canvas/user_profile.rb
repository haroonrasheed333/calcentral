module Canvas
  class UserProfile < Proxy

    def user_profile
      request("users/sis_login_id:#{@uid}/profile", "_user_profile")
    end

    def existence_check
      true
    end

  end
end
