module Canvas
  class Course < Proxy
    def initialize(options = {})
      super(options)
      @course_id = options[:course_id]
    end

    def self.cache_key course_id
      "global/#{self.name}/#{course_id}"
    end

    def course
      request_uncached("courses/sis_course_id:#{@course_id}?include[]=term", "_course")
    end

  end
end
