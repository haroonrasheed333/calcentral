module Canvas
  class UserCourses < Proxy

    def courses
      request("courses?include[]=term&as_user_id=sis_login_id:#{@uid}", "_courses")
    end

  end
end
