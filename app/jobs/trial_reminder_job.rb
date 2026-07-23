# Roda uma vez por dia (cron do GoodJob, ver config/environments/production.rb)
# e avisa trials que já usam a plataforma há 3 dias e ainda não receberam o
# lembrete. trial_reminder_sent_at evita reenvio automático nos dias seguintes;
# o mesmo campo é marcado quando o admin dispara manualmente pelo painel.
class TrialReminderJob < ApplicationJob
  queue_as :default

  def perform
    due_trials.find_each do |user|
      TrialMailer.reminder_email(user).deliver_now
      user.update_column(:trial_reminder_sent_at, Time.current)
    end
  end

  private

  def due_trials
    User.trials
        .where(trial_reminder_sent_at: nil)
        .where("created_at <= ?", 3.days.ago)
        .where("trial_expires_at > ?", Time.current)
  end
end
