class RostersCommon < AbstractModel

  PHOTO_UNAVAILABLE_FILENAME = 'photo_unavailable_official_72x96.jpg'

  def self.cache_key(course_id)
    "global/#{self.name}/#{course_id}"
  end

  def initialize(uid, options={})
    @uid = uid
    @course_id = options[:course_id]
    @campus_course_id = @course_id
    @canvas_course_id = @course_id
  end

  def get_feed
    if user_authorized?
      self.class.fetch_from_cache "#{@course_id}" do
        get_feed_internal
      end
    else
      nil
    end
  end

  def photo_data_or_file(student_id)
    roster = get_feed
    return nil if roster.nil?
    match = roster[:students].index {|stu| stu[:id].to_s == student_id.to_s}
    if (match)
      student = roster[:students][match]
      if student[:enroll_status] == 'E'
        if (photo_row = CampusData.get_photo(student[:login_id]))
          return {
              size: photo_row['bytes'],
              data: photo_row['photo']
          }
        end
      end
    end
    {
        filename: File.join(Rails.root, 'app/assets/images', PHOTO_UNAVAILABLE_FILENAME)
    }
  end
end
