# Roda a cada 6h (cron do GoodJob, ver config/environments/production.rb).
# Avisa por push (nunca email) quem já praticou antes e sumiu por 48h+.
# inactivity_nudge_sent_at garante um único aviso por ausência: só dispara
# de novo depois que o aluno volta a praticar. Não se aplica a trials
# (esses têm o TrialReminderJob) nem a quem nunca ativou push.
class InactivityNudgeJob < ApplicationJob
  queue_as :default

  def perform
    candidates.find_each do |student|
      last_activity_at = student.quiz_attempts.maximum(:submitted_at)
      next if last_activity_at.nil? || last_activity_at > 48.hours.ago
      next if student.inactivity_nudge_sent_at.present? && student.inactivity_nudge_sent_at >= last_activity_at

      title, body = copy_for(student.language)
      PushNotificationService.send_to_user(
        student,
        title: title,
        body:  body,
        url:   Rails.application.routes.url_helpers.student_dashboard_url(
                 host: Rails.application.config.action_mailer.default_url_options[:host]
               )
      )
      student.update_column(:inactivity_nudge_sent_at, Time.current)
    end
  end

  private

  def candidates
    User.where(role: "student").joins(:push_subscriptions).distinct
  end

  def copy_for(language)
    case language
    when "fr" then ["Vous nous manquez · sentimos sua falta !", "Et si on pratiquait le portugais · português 5 minutes aujourd'hui ?"]
    when "en" then ["We miss you · sentimos sua falta!", "How about 5 minutes of Portuguese · português today?"]
    else           ["Sentimos sua falta!", "Que tal 5 minutinhos de português hoje?"]
    end
  end
end
