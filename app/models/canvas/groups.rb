module Canvas
  class Groups < Proxy

    def groups
      request("users/self/groups?as_user_id=sis_login_id:#{@uid}", "_groups")
    end

  end
end
