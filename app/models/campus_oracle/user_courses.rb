module CampusOracle
  class UserCourses < BaseProxy
    extend Proxies::EnableForActAs

    APP_ID = "Campus"

    def initialize(options = {})
      super(Settings.sakai_proxy, options)
      @uid = @settings.fake_user_id if @fake
    end

    def self.expires_in
      self.bearfacts_derived_expiration
    end

    def self.access_granted?(uid)
      !uid.blank?
    end

    def academic_terms
      @settings.academic_terms
    end

    def get_all_campus_courses
      # Because this data structure is used by multiple top-level feeds, it's essential
      # that it be cached efficiently.
      self.class.fetch_from_cache "all-courses-#{@uid}" do
        campus_classes = {}

        if merge_explicit_instructing(campus_classes)
          merge_nested_instructing(campus_classes)
        end
        merge_enrollments(campus_classes)

        # Sort the hash in descending order of semester.
        campus_classes = Hash[campus_classes.sort.reverse]

        # Merge each section's schedule, location, and instructor list.
        # TODO Is this information useful for non-current terms?
        campus_classes.values.each do |semester|
          semester.each do |course|
            course[:sections].each do |section|
              proxy = CampusOracle::CourseSections.new({term_yr: course[:term_yr],
                                                     term_cd: course[:term_cd],
                                                     ccn: section[:ccn]})
              section.merge!(proxy.get_section_data)
            end
          end
        end

        campus_classes
      end
    end

    def merge_enrollments(campus_classes)
      previous_item = {}
      enrollments = CampusOracle::Queries.get_enrolled_sections(@uid, academic_terms.student)
      enrollments.each do |row|
        if (item = row_to_feed_item(row, previous_item))
          item[:role] = 'Student'
          item[:unit] = row['unit']
          item[:pnp_flag] = row['pnp_flag']
          item[:grade] = row["grade"]
          item[:cred_cd] = row["cred_cd"]
          item[:transcript_unit] = row["transcript_unit"]
          if row['enroll_status'] == 'W'
            item[:waitlist_position] = row['wait_list_seq_num']
            item[:enroll_limit] = row['enroll_limit']
          end
          semester_key = "#{item[:term_yr]}-#{item[:term_cd]}"
          campus_classes[semester_key] ||= []
          campus_classes[semester_key] << item
          previous_item = item
        end
      end
    end

    def merge_explicit_instructing(campus_classes)
      previous_item = {}
      assigneds = CampusOracle::Queries.get_instructing_sections(@uid, academic_terms.instructor)
      is_instructing = assigneds.present?
      assigneds.each do |row|
        if (item = row_to_feed_item(row, previous_item))
          item[:role] = 'Instructor'
          semester_key = "#{item[:term_yr]}-#{item[:term_cd]}"
          campus_classes[semester_key] ||= []
          campus_classes[semester_key] << item
          previous_item = item
        end
      end
      is_instructing
    end

    # This is done in a separate step so that implicitly nested secondary sections
    # are ordered after explicitly assigned primary sections.
    def merge_nested_instructing(campus_classes)
      campus_classes.values.each do |semester|
        semester.each do |course|
          if course[:role] == 'Instructor'
            primaries = course[:sections].select { |s| s[:is_primary_section] }
            if primaries.present? && Berkeley::CourseOptions::MAPPING[course[:course_option]]
              secondaries = get_all_secondary_sections(course)
              if secondaries.present?
                # Use a hash to avoid duplicates when an instructor is assigned more than one primary.
                nested_secondaries = {}
                primaries.each do |prim|
                  secondaries.each do |sec|
                    if Berkeley::CourseOptions.nested?(course[:course_option], prim[:section_number], sec)
                      nested_secondaries[sec['course_cntl_num']] = row_to_section_data(sec)
                    end
                  end
                end
                course[:sections].concat(nested_secondaries.values)
              end
            end
          end
        end
      end
    end

    def get_all_secondary_sections(course)
      self.class.fetch_from_cache "secondaries-#{course[:term_yr]}-#{course[:term_cd]}-#{course[:dept]}-#{course[:catid]}" do
        CampusOracle::Queries.get_course_secondary_sections(course[:term_yr], course[:term_cd],
                                                 course[:dept], course[:catid])
      end
    end

    def get_all_transcripts
      self.class.fetch_from_cache "all-transcripts-#{@uid}" do
        CampusOracle::Queries.get_transcript_grades(@uid, academic_terms.student)
      end
    end

    def has_student_history?
      self.class.fetch_from_cache "has_student_history-#{@uid}" do
        CampusOracle::Queries.has_student_history?(@uid, academic_terms.student)
      end
    end

    def has_instructor_history?
      self.class.fetch_from_cache "has_instructor_history-#{@uid}" do
        CampusOracle::Queries.has_instructor_history?(@uid, academic_terms.instructor)
      end
    end

    def get_selected_sections(term_yr, term_cd, ccns)
      self.class.fetch_from_cache "selected_sections-#{term_yr}-#{term_cd}-#{ccns.join(',')}" do
        campus_classes = {}
        sections = CampusOracle::Queries.get_sections_from_ccns(term_yr, term_cd, ccns)
        previous_item = {}
        sections.each do |row|
          if (item = row_to_feed_item(row, previous_item))
            semester_key = "#{item[:term_yr]}-#{item[:term_cd]}"
            campus_classes[semester_key] ||= []
            campus_classes[semester_key] << item
            previous_item = item
          end
        end
        campus_classes
      end
    end

    def row_to_feed_item(row, previous_item)
      course_id = "#{row['dept_name']}-#{row['catalog_id']}-#{row['term_yr']}-#{row['term_cd']}"
      # Make it embeddable as an element in a URL path.
      course_id = course_id.downcase.gsub(/[^a-z0-9-]+/, '_')
      if course_id == previous_item[:id]
        previous_item[:sections] << row_to_section_data(row)
        nil
      else
        course_data = {
          id: course_id,
          term_yr: row['term_yr'],
          term_cd: row['term_cd'],
          dept: row['dept_name'],
          dept_desc: row['dept_description'],
          catid: row['catalog_id'],
          course_code: "#{row['dept_name']} #{row['catalog_id']}",
          course_catalog: row['catalog_id'],
          emitter: 'Campus',
          name: row['course_title'],
          sections: [
            row_to_section_data(row)
          ]
        }
        # This only applies to instructors and will be skipped for students.
        if (course_option = row['course_option'])
          course_data[:course_option] = course_option
        end
        course_data
      end
    end

    def row_to_section_data(row)
      section_data = {
        ccn: get_ccn(row['course_cntl_num'].to_s),
        instruction_format: row['instruction_format'],
        is_primary_section: (row['primary_secondary_cd'] == 'P'),
        section_label: "#{row['instruction_format']} #{row['section_num']}",
        section_number: row['section_num']
      }
      # This only applies to enrollment records and will be skipped for instructors.
      if row['enroll_status'] == 'W'
        section_data[:waitlist_position] = row['wait_list_seq_num']
        section_data[:enroll_limit] = row['enroll_limit']
      end
      section_data
    end

    def get_ccn(ccn)
      return ccn unless ccn.length < 5
      "0" * (5 - ccn.length) + ccn
    end

  end
end
