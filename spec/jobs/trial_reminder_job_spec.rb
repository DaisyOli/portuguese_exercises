require 'rails_helper'

RSpec.describe TrialReminderJob, type: :job do
  it 'envia o lembrete para trials com 3 dias ou mais, ainda ativos e sem lembrete enviado' do
    user = create(:user, :trial, created_at: 3.days.ago, trial_expires_at: 4.days.from_now)

    expect {
      described_class.perform_now
    }.to change { ActionMailer::Base.deliveries.count }.by(1)

    expect(user.reload.trial_reminder_sent_at).to be_present
  end

  it 'não envia para trials com menos de 3 dias' do
    create(:user, :trial, created_at: 1.day.ago, trial_expires_at: 6.days.from_now)

    expect {
      described_class.perform_now
    }.not_to change { ActionMailer::Base.deliveries.count }
  end

  it 'não envia de novo para trials que já receberam o lembrete' do
    create(:user, :trial, created_at: 3.days.ago, trial_expires_at: 4.days.from_now,
                          trial_reminder_sent_at: 1.hour.ago)

    expect {
      described_class.perform_now
    }.not_to change { ActionMailer::Base.deliveries.count }
  end

  it 'não envia para trials já expirados' do
    create(:user, :trial, created_at: 8.days.ago, trial_expires_at: 1.day.ago)

    expect {
      described_class.perform_now
    }.not_to change { ActionMailer::Base.deliveries.count }
  end
end
