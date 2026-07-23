require 'rails_helper'

RSpec.describe "Admin::Trials", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:admin) { create(:user, :admin) }
  let(:trial) { create(:user, :trial) }

  describe "POST /admin/trials/:id/send_reminder" do
    context "como admin" do
      it "envia o lembrete e marca trial_reminder_sent_at" do
        sign_in admin

        expect {
          post admin_send_trial_reminder_path(trial)
        }.to have_enqueued_mail(TrialMailer, :reminder_email)

        expect(trial.reload.trial_reminder_sent_at).to be_present
        expect(response).to redirect_to(admin_root_path)
      end
    end

    context "sem ser admin" do
      it "não envia e redireciona" do
        teacher = create(:user, :teacher)
        sign_in teacher

        expect {
          post admin_send_trial_reminder_path(trial)
        }.not_to have_enqueued_mail(TrialMailer, :reminder_email)

        expect(response).to redirect_to(root_path)
      end
    end
  end
end
