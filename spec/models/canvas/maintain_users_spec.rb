require "spec_helper"

describe Canvas::MaintainUsers do

  describe "#categorize_user_accounts" do
    let(:known_uids) { [] }
    let(:sis_id_changes) { {} }
    let(:account_changes) { [] }
    before { subject.categorize_user_account(existing_account, campus_rows, known_uids, sis_id_changes, account_changes) }

    context 'when email changes' do
      let(:uid) { rand(999999).to_s }
      let(:existing_account) {
        {
          'canvas_user_id' => rand(999999).to_s,
          'user_id' => "UID:#{uid}",
          'login_id' => uid,
          'first_name' => 'Ema',
          'last_name' => 'Ilcha',
          'email' => 'old@example.edu',
          'status' => 'active'
        }
      }
      let(:campus_rows) { [
        {
          'ldap_uid' => uid.to_i,
          'first_name' => 'Ema',
          'last_name' => 'Ilcha',
          'email_address' => 'new@example.edu',
          'affiliations' => 'EMPLOYEE-TYPE-STAFF'
        }
      ] }
      it 'finds email change' do
        expect(account_changes.length).to eq(1)
        expect(sis_id_changes.length).to eq(0)
        expect(known_uids.length).to eq(1)
        new_account = account_changes[0]
        expect(new_account['email']).to eq('new@example.edu')
      end
    end

    context 'when user becomes a student' do
      let(:canvas_user_id) { rand(999999).to_s }
      let(:changed_sis_id_uid) { rand(999999).to_s }
      let(:changed_sis_id_student_id) { rand(999999).to_s }
      let(:existing_account) {
        {
          'canvas_user_id' => canvas_user_id,
          'user_id' => "UID:#{changed_sis_id_uid}",
          'login_id' => changed_sis_id_uid,
          'first_name' => 'Sissy',
          'last_name' => 'Changer',
          'email' => "#{changed_sis_id_uid}@example.edu",
          'status' => 'active'
        }
      }
      let(:campus_rows) { [
        {
          'ldap_uid' => changed_sis_id_uid.to_i,
          'first_name' => 'Sissy',
          'last_name' => 'Changer',
          'email_address' => "#{changed_sis_id_uid}@example.edu",
          'affiliations' => 'EMPLOYEE-TYPE-STAFF,STUDENT-TYPE-REGISTERED',
          'student_id' => changed_sis_id_student_id.to_i
        }
      ] }
      it 'finds SIS ID change' do
        expect(account_changes.length).to eq(0)
        expect(sis_id_changes.length).to eq(1)
        expect(known_uids.length).to eq(1)
        expect(sis_id_changes["sis_login_id:#{changed_sis_id_uid}"]).to eq(changed_sis_id_student_id)
      end
    end

    context 'when there are no changes' do
      let(:uid) { rand(999999).to_s }
      let(:existing_account) {
        {
          'canvas_user_id' => rand(999999).to_s,
          'user_id' => "UID:#{uid}",
          'login_id' => uid,
          'first_name' => 'Noam',
          'last_name' => 'Changey',
          'email' => "#{uid}@example.edu",
          'status' => 'active'
        }
      }
      let(:campus_rows) { [
        {
          'ldap_uid' => uid.to_i,
          'first_name' => 'Noam',
          'last_name' => 'Changey',
          'email_address' => "#{uid}@example.edu",
          'affiliations' => 'EMPLOYEE-TYPE-STAFF,STUDENT-STATUS-EXPIRED',
          'student_id' => 9999999
        }
      ] }
      it 'just notes the UID' do
        expect(account_changes.length).to eq(0)
        expect(sis_id_changes.length).to eq(0)
        expect(known_uids.length).to eq(1)
      end
    end

    context 'when Canvas has a non-LDAP account' do
      let(:uid) { 'some_special_admin_account' }
      let(:existing_account) {
        {
          'canvas_user_id' => rand(999999).to_s,
          'user_id' => uid,
          'login_id' => uid,
          'first_name' => 'Uneeda',
          'last_name' => 'Integer',
          'email' => "#{uid}@example.edu",
          'status' => 'active'
        }
      }
      let(:campus_rows) { [
        {
          'ldap_uid' => 0,
          'first_name' => 'Sumotha',
          'last_name' => 'Match',
          'email_address' => 'zero@example.edu',
          'affiliations' => 'STUDENT-TYPE-REGISTERED',
          'student_id' => 9999999
        }
      ] }
      it 'skips the record' do
        expect(account_changes.length).to eq(0)
        expect(sis_id_changes.length).to eq(0)
        expect(known_uids.length).to eq(0)
      end
    end
  end

  describe "#derive_sis_user_id" do
    let(:uid) { rand(999999).to_s }
    let(:student_id) { rand(999999).to_s }
    context 'when an ex-student' do
      let(:affiliations) { 'AFFILIATE-TYPE-GENERAL,EMPLOYEE-STATUS-EXPIRED,STUDENT-STATUS-EXPIRED' }
      it 'uses the LDAP UID' do
        expect(subject.derive_sis_user_id({
          'ldap_uid' => uid, 'student_id' => student_id, 'affiliations' => affiliations
        })).to eq("UID:#{uid}")
      end
    end
    context 'when a student employee' do
      let(:affiliations) { 'STUDENT-TYPE-REGISTERED,EMPLOYEE-TYPE-ACADEMIC' }
      it 'uses the student ID' do
        expect(subject.derive_sis_user_id({
          'ldap_uid' => uid, 'student_id' => student_id, 'affiliations' => affiliations
        })).to eq(student_id)
      end
    end
    context 'when a student with registration issues' do
      let(:affiliations) { 'EMPLOYEE-TYPE-STAFF,STUDENT-TYPE-NOT REGISTERED' }
      it 'uses the student ID' do
        expect(subject.derive_sis_user_id({
          'ldap_uid' => uid, 'student_id' => student_id, 'affiliations' => affiliations
        })).to eq(student_id)
      end
    end
    context 'when missing a student ID' do
      let(:affiliations) { 'STUDENT-TYPE-REGISTERED' }
      it 'uses the LDAP UID' do
        expect(subject.derive_sis_user_id({
          'ldap_uid' => uid, 'student_id' => nil, 'affiliations' => affiliations
        })).to eq("UID:#{uid}")
      end
    end
    context 'when fancy SIS user IDs are disabled' do
      before { Settings.canvas_proxy.stub(:mixed_sis_user_id).and_return(nil) }
      it 'uses the LDAP UID for everyone' do
        expect(subject.derive_sis_user_id({
          'ldap_uid' => uid, 'student_id' => student_id, 'affiliations' => 'STUDENT-TYPE-REGISTERED'
        })).to eq(uid)
      end
    end
  end

  describe "#change_sis_user_id" do
    let(:canvas_user_id) { rand(999999) }
    let(:matching_login_id) { rand(999999) }
    let(:new_sis_id) { "UID:#{rand(99999)}" }
    let(:old_sis_id) { rand(99999).to_s }
    it 'finds and modifies a user login record' do
      canvas_logins_response = double()
      canvas_logins_response.stub(:status).and_return(200)
      canvas_logins_response.stub(:body).and_return(
        [
          {
            account_id: 90242,
            id: matching_login_id,
            sis_user_id: old_sis_id,
            unique_id: old_sis_id,
            user_id: canvas_user_id
          },
          {
            account_id: 90242,
            id: rand(99999),
            sis_user_id: nil,
            unique_id: "test-#{rand(99999)}",
            user_id: canvas_user_id
          }
        ].to_json
      )
      fake_logins_proxy = double()
      fake_logins_proxy.should_receive(:user_logins).with(canvas_user_id).and_return(canvas_logins_response)
      fake_logins_proxy.should_receive(:change_sis_user_id).with(matching_login_id, new_sis_id).and_return(
          double().stub(:status).and_return(200)
      )
      Canvas::Logins.stub(:new).and_return(fake_logins_proxy)
      subject.change_sis_user_id(canvas_user_id, new_sis_id)
    end
  end

end
