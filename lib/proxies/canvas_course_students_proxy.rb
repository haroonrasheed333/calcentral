class CanvasCourseStudentsProxy < CanvasProxy

  include SafeJsonParser

  def initialize(options = {})
    super(options)
    @course_id = options[:course_id]
  end

  def self.cache_key course_id
    "global/#{self.name}/#{course_id}"
  end

  def full_students_list
    self.class.fetch_from_cache @course_id do
      all_students = []
      params = "enrollment_type=student&include[]=enrollments&per_page=30"
      while params do
        response = request_uncached(
            "courses/#{@course_id}/users?#{params}",
            "_course_students"
        )
        break unless (response && response.status == 200 && students_list = safe_json(response.body))
        all_students.concat(students_list)
        params = next_page_params(response)
      end
      all_students
    end
  end

end
