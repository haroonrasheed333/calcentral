class MyAcademics::GpaUnits

  include MyAcademics::AcademicsModule

  def merge(data)
    student_info = CampusOracle::Queries.get_student_info(@uid) || {}
    return data if student_info.nil?

    data[:gpa_units] = {
      cumulative_gpa: student_info["cum_gpa"].nil? ? nil: student_info["cum_gpa"].to_f,
      total_units: student_info["tot_units"].nil? ? nil : student_info["tot_units"].to_f
    }
  end

end
