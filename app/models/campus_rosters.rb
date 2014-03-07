class CampusRosters
  include ActiveAttr::Model, ClassLogger, SafeJsonParser
  extend Calcentral::Cacheable

  PHOTO_UNAVAILABLE_FILENAME = 'photo_unavailable_official_72x96.jpg'

  def self.cache_key(cache_key)
    "global/#{self.name}/#{cache_key}"
  end

  def initialize(uid, options={})
    @uid = uid
    @class_slug = options[:class_slug]
    @semester_slug = options[:semester_slug]
    @ccns = options[:ccns]
    @cache_key = "#{@class_slug}-#{@semester_slug}"
  end

  # Must be protected by a call to "user_authorized?"!
  def get_feed
    if user_authorized?
      self.class.fetch_from_cache "#{@cache_key}" do
        get_feed_internal
      end
    else
      nil
    end
  end

  def get_feed_internal
    feed = {
        campus_course: {
            id: "#{@class_slug}-#{@semester_slug}"
        },
        sections: [],
        students: []
    }
    campus_enrollment_map = {}

    term = get_term(@semester_slug)

    @ccns.each do |ccn|
      section_data = CampusData.get_sections_from_ccns(term[:term_yr], term[:term_cd], [ccn])

      name = "#{section_data[0]['instruction_format']} #{section_data[0]['section_num']}"

      feed[:sections] << {
        id: ccn,
        name: name,
      }

      section_enrollments = CampusData.get_enrolled_students(ccn, term[:term_yr], term[:term_cd])
      section_enrollments.each do |enr|
        if (existing_entry = campus_enrollment_map[enr['ldap_uid']])
          # We include waitlisted students in the roster. However, we do not show the official photo if the student
          # is waitlisted in ALL sections.
          if existing_entry[:enroll_status] == 'W' &&
              enr['enroll_status'] == 'E'
            existing_entry[:enroll_status] = 'E'
          end
          campus_enrollment_map[enr['ldap_uid']][:section_ccns] |= [ccn]
        else
          campus_enrollment_map[enr['ldap_uid']] = {
              student_id: enr['student_id'],
              first_name: enr['first_name'],
              last_name: enr['last_name'],
              enroll_status: enr['enroll_status'],
              section_ccns: [ccn],
              primary_ccn: ccn
          }
        end
      end
    end
    return feed if campus_enrollment_map.empty?
    campus_enrollment_map.keys.each do |id|
      campus_student = campus_enrollment_map[id]
      campus_student[:id] = id
      campus_student[:profile_url] = 'https://calnet.berkeley.edu/directory/details.pl?uid=' + id
      campus_student[:sections] = []
      campus_student[:section_ccns].each do |section_ccn|
        campus_student[:sections].push({id: section_ccn})
      end
      if campus_student[:enroll_status] == 'E'
        campus_student[:photo] = "/campus/#{@class_slug}/#{campus_student[:primary_ccn]}/#{@semester_slug}/photo/#{id}"
      end
      feed[:students] << campus_student
    end
    feed
  end

  def photo_data_or_file(student_campus_id)
    @ccns = [@ccns]
    roster = get_feed
    return nil if roster.nil?
    match = roster[:students].index {|stu| stu[:id].to_s == student_campus_id.to_s}
    if (match)
      student = roster[:students][match]
      if student[:enroll_status] == 'E'
        if (photo_row = CampusData.get_photo(student_campus_id))
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

  def user_authorized?
    term = get_term(@semester_slug)
    teachers_list = CampusData.get_section_instructors(term[:term_yr], term[:term_cd], @ccns[0])
    match = teachers_list.index {|teacher| teacher['ldap_uid'] == @uid}
    if match.nil?
      logger.warn("Unauthorized request from user = #{@uid} for Canvas course #{@canvas_course_id}")
    end
    !match.nil?
    true
  end

  def get_term(semester_slug)
    semester = semester_slug.split('-')[0]
    term_yr = semester_slug.split('-')[1]

    case semester
      when 'fall'
        term_cd = 'D'
      when 'spring'
        term_cd = 'B'
      when 'summer'
        term_cd = 'C'
    end
    return {
      term_cd: term_cd,
      term_yr: term_yr
    }
  end

end
