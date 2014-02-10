require "spec_helper"

describe MyAcademics::TeachingCanvas do
  let(:uid) {rand(99999).to_s}
  let(:ccn) {rand(99999)}
  let(:course_id) {"econ-#{rand(999)}B"}
  let(:campus_course_base) do
    {
      slug: course_id,
      sections: [{
        ccn: ccn.to_s
      }],
      class_sites: []
    }
  end
  let(:campus_courses) do
    [{
      name: TermCodes.to_english(CampusData.current_year, CampusData.current_term),
      slug: TermCodes.to_slug(CampusData.current_year, CampusData.current_term),
      classes: [
        campus_course_base
      ]
    }]
  end
  subject do
    MyAcademics::TeachingCanvas.new(uid).merge_sites(campus_courses)
    campus_courses.first[:classes].first[:class_sites]
  end

  context 'when no Canvas account' do
    before {CanvasProxy.stub(:access_granted?).with(uid).and_return(false)}
    it {should eq []}
  end

  describe '#merge_sites' do
    let(:canvas_site_id) {rand(99999).to_s}
    let(:canvas_site_base) do
      {
        id: canvas_site_id,
        site_url: "something/#{canvas_site_id}",
        name: "CODE #{ccn}",
        short_description: "A barrel of #{ccn} monkeys",
        term_yr: term_yr,
        term_cd: term_cd,
        emitter: CanvasProxy::APP_NAME
      }
    end
    let(:group_id) {rand(99999).to_s}
    let(:group_base) do
      {
        id: group_id,
        name: "Group #{group_id}",
        site_url: "somewhere/#{group_id}",
        emitter: CanvasProxy::APP_NAME
      }
    end
    before {CanvasProxy.stub(:access_granted?).with(uid).and_return(true)}
    before {CanvasMergedUserSites.stub(:new).with(uid).and_return(double(get_feed: canvas_sites))}

    context 'when Canvas course has an academic term' do
      let(:term_yr) {CampusData.current_year}
      let(:term_cd) {CampusData.current_term}
      context 'when Canvas course site matches a campus section' do
        let(:canvas_site) {canvas_site_base.merge({sections: [{ccn: ccn.to_s}]})}
        let(:canvas_sites) {{courses: [canvas_site], groups: []}}
        its(:size) {should eq 1}
        it 'points back to campus course' do
          site = subject.first
          expect(site[:id]).to eq canvas_site_id
          expect(site[:emitter]).to eq CanvasProxy::APP_NAME
          expect(site[:name]).to eq canvas_site_base[:name]
          expect(site[:sections].first[:ccn]).to eq ccn.to_s
          expect(site[:site_type]).to eq 'course'
        end
      end
      # By default, CCN strings are filled out to five digits by prefixing zeroes.
      # However, shorter strings should still match.
      context 'when Canvas section CCN does not prefix zero' do
        let(:ccn_int) {rand(999)}
        let(:ccn) {"00#{ccn_int}"}
        let(:canvas_site) {canvas_site_base.merge({sections: [{ccn: ccn_int.to_s}]})}
        let(:canvas_sites) {{courses: [canvas_site], groups: []}}
        its(:size) {should eq 1}
        it 'points back to campus course' do
          site = subject.first
          expect(site[:id]).to eq canvas_site_id
          expect(site[:emitter]).to eq CanvasProxy::APP_NAME
          expect(site[:name]).to eq canvas_site_base[:name]
          expect(site[:sections].first[:ccn]).to eq ccn
          expect(site[:site_type]).to eq 'course'
        end
      end
      context 'when Canvas group site links to a matching course site' do
        let(:group) {group_base.merge(course_id: canvas_site_id)}
        let(:canvas_site) {canvas_site_base.merge({sections: [{ccn: ccn.to_s}]})}
        let(:canvas_sites) {{courses: [canvas_site], groups: [group]}}
        its(:size) {should eq 2}
        it 'is included with campus course' do
          site = subject.select{|s| s[:site_type] == 'group'}.first
          expect(site[:id]).to eq group_id
          expect(site[:emitter]).to eq CanvasProxy::APP_NAME
          expect(site[:name]).to eq group_base[:name]
          expect(site[:site_type]).to eq 'group'
          expect(site[:source]).to eq canvas_site_base[:name]
        end
      end
      context 'when Canvas group is not linked to a course site' do
        let(:canvas_site) {canvas_site_base.merge({sections: [{ccn: ccn.to_s}]})}
        let(:canvas_sites) {{courses: [canvas_site], groups: [group_base]}}
        its(:size) {should eq 1}
      end
      context 'when Canvas course site does not match official campus enrollment' do
        let(:canvas_site) {canvas_site_base.merge({sections: [{ccn: rand(9999).to_s}]})}
        let(:canvas_sites) {{courses: [canvas_site], groups: []}}
        its(:size) {should eq 0}
      end
    end
    context 'when Canvas course site is not within an academic term' do
      let(:term_yr) {nil}
      let(:term_cd) {nil}
      let(:canvas_sites) {{courses: [canvas_site_base], groups: []}}
      its(:size) {should eq 0}
    end
    context 'when Canvas group links to a course site without an academic term' do
      let(:term_yr) {nil}
      let(:term_cd) {nil}
      let(:group) {group_base.merge(course_id: canvas_site_id)}
      let(:canvas_sites) {{courses: [canvas_site_base], groups: [group]}}
      its(:size) {should eq 0}
    end
  end

end
