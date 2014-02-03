class MyClasses::Canvas
  include MyClasses::ClassesModule

  def merge_sites(campus_courses, sites)
    return unless CanvasProxy.access_granted?(@uid)
    canvas_sites = CanvasMergedUserSites.new(@uid).get_feed
    included_course_sites = {}
    canvas_sites[:courses].each do |course_site|
      if (entry = course_site_entry(campus_courses, course_site))
        sites << entry
        included_course_sites[entry[:id]] = {
          source: entry[:name],
          courses: entry[:courses]
        }
      end
    end
    canvas_sites[:groups].each do |group_site|
      if (entry = group_site_entry(included_course_sites, group_site))
        sites << entry
      end
    end
  end

  def group_site_entry(included_course_sites, group_site)
    if (linked_id = group_site[:course_id]) && (linked_entry = included_course_sites[linked_id])
      {
        emitter: group_site[:emitter],
        id: group_site[:id],
        name: group_site[:name],
        site_type: 'group',
        site_url: group_site[:site_url]
      }.merge(linked_entry)
    else
      nil
    end
  end
end
