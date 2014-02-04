module MyClasses::ClassesModule
  extend self

  def initialize(uid)
    @uid = uid
    @current_terms = Settings.sakai_proxy.current_terms_codes
  end

  def current_term?(term_yr, term_cd)
    @current_terms.index {|t| t.term_yr == term_yr && t.term_cd == term_cd}.present?
  end

  def course_site_entry(campus_courses, course_site)
    # My Classes only includes course sites for current terms.
    if (term_yr = course_site[:term_yr]) && (term_cd = course_site[:term_cd]) && current_term?(term_yr, term_cd)
      linked_campus = []
      if (sections = course_site[:sections])
        candidate_ccns = sections.collect {|s| s[:ccn].to_i}
        campus_courses.each do |campus|
          if campus[:term_yr] == term_yr && campus[:term_cd]
            if campus[:sections].index {|s| candidate_ccns.include?(s[:ccn].to_i)}.present?
              linked_campus << {id: campus[:id]}
            end
          end
        end
      end
      {
        emitter: course_site[:emitter],
        id: course_site[:id],
        name: course_site[:name],
        short_description: course_site[:short_description],
        site_type: 'course',
        site_url: course_site[:site_url],
        term_cd: term_cd,
        term_yr: term_yr,
        courses: linked_campus
      }
    else
      nil
    end
  end

end
