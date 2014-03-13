module MyAcademics::AcademicsModule
  extend self

  def initialize(uid)
    @uid = uid
  end

  def to_text(element)
    if element.blank?
      return ""
    else
      return element.text.strip
    end
  end

  def to_time(element)
    str = to_text(element)
    num = str.gsub(/^0/, "")
    formatted = num.insert(num.length - 2, ":")
    formatted
  end

  def make_slug(text)
    if text.blank?
      ""
    else
      text.downcase.gsub(/[^a-z0-9]+/, '-').chomp('-')
    end
  end

  # Link campus courses to internal class pages for the current semester.
  def class_to_url(term_cd, term_year, department, catalog_id, role)
    teaching_str = (role == 'Instructor') ? 'teaching-' : ''
    "/academics/#{teaching_str}semester/#{TermCodes.to_slug(term_year, term_cd)}/class/#{course_to_slug(department, catalog_id)}"
  end

  def course_to_slug(department, catalog_id)
    "#{department.downcase.gsub(/[^a-z0-9]+/, '_')}-#{catalog_id.downcase.gsub(/[^a-z0-9]+/, '_')}"
  end

  def semester_info(term_yr, term_cd)
    {
      name: TermCodes.to_english(term_yr, term_cd),
      slug: TermCodes.to_slug(term_yr, term_cd),
      term_cd: term_cd,
      term_yr: term_yr,
      classes: []
    }
  end

  def class_info(campus_course)
    {
      course_number: campus_course[:course_code],
      dept: campus_course[:dept],
      course_catalog: campus_course[:course_catalog],
      dept_desc: campus_course[:dept_desc],
      slug: course_to_slug(campus_course[:dept], campus_course[:catid]),
      title: campus_course[:name],
      sections: campus_course[:sections],
      course_id: campus_course[:id]
    }
  end

  def course_site_entry(course_site)
    {
      emitter: course_site[:emitter],
      id: course_site[:id],
      name: course_site[:name],
      short_description: course_site[:short_description],
      site_type: 'course',
      site_url: course_site[:site_url]
    }
  end

  def current_term
    Settings.sakai_proxy.current_terms_codes[0]
  end

  def time_bucket(term_yr, term_cd)
    if term_yr < current_term.term_yr || (term_yr == current_term.term_yr && term_cd < current_term.term_cd)
      bucket = 'past'
    elsif term_yr > current_term.term_yr || (term_yr == current_term.term_yr && term_cd > current_term.term_cd)
      bucket = 'future'
    else
      bucket = 'current'
    end
    bucket
  end

end
