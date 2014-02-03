class CanvasMergedUserSites
  include ClassLogger
  extend Calcentral::Cacheable

  def initialize(uid)
    @uid = uid
    @url_root = Settings.canvas_proxy.url_root
  end

  def get_feed
    self.class.fetch_from_cache @uid do
      get_feed_internal
    end
  end

  def get_feed_internal
    merged_sites = {
        courses: [],
        groups: []
    }
    response = CanvasUserCoursesProxy.new(user_id: @uid).courses
    return merged_sites unless (response && response.status == 200)
    courses = JSON.parse(response.body)
    courses.each do |course|
      course_id = course['id']
      # We collect sections and CCNs as an admin, not as the user. Most site members
      # do not have access to that information.
      response = CanvasCourseSectionsProxy.new(course_id: course_id).sections_list
      return nil unless (response && response.status == 200)
      merged_sites[:courses] << merge_course_with_sections(course, JSON.parse(response.body))
    end

    response = CanvasGroupsProxy.new(user_id: @uid).groups
    return merged_sites unless (response && response.status == 200)
    group_sites = JSON.parse(response.body)
    group_sites.each do |group|
      merged_sites[:groups] << get_group_data(group)
    end

    merged_sites
  end

  def merge_course_with_sections(course, canvas_sections)
    course_id = course['id']
    term_name = course['term']['name']
    term_hash = TermCodes.from_english(term_name) || {}
    sis_sections = []
    canvas_sections.each do |canvas_section|
      sis_id = canvas_section['sis_section_id']
      if (campus_section = CanvasProxy.sis_section_id_to_ccn_and_term(sis_id))
        # Check our assumption that Canvas and campus semesters are aligned.
        if TermCodes.to_english(campus_section[:term_yr], campus_section[:term_cd]) == term_name
          sis_sections << {ccn: campus_section[:ccn]}
        else
          logger.error("Canvas course #{course_id} is in term #{term_name} but links to section #{campus_section}")
        end
      else
        logger.debug("Unparsable sis_section_id #{sis_id} for Canvas course #{course_id}")
      end
    end
    {
      emitter: CanvasProxy::APP_NAME,
      id: course_id.to_s,
      name: course['course_code'],
      sections: sis_sections,
      short_description: course['name'],
      site_url: "#{@url_root}/courses/#{course_id}",
      term_name: term_name,
      term_yr: term_hash[:term_yr],
      term_cd: term_hash[:term_cd]
    }
  end

  def get_group_data(group)
    group_data = {
      emitter: CanvasProxy::APP_NAME,
      id: group['id'].to_s,
      name: group['name'],
      site_url: "#{@url_root}/groups/#{group['id']}"
    }
    if group['context_type'] == 'Course'
      group_data[:course_id] = group['course_id']
    end
    group_data
  end

end
