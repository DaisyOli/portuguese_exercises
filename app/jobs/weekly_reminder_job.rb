# Roda toda segunda-feira (cron do GoodJob, ver config/environments/production.rb).
# Nunca esteve de fato agendado: só existia como rake task pensada para o
# Heroku Scheduler, que nunca foi configurado lá (só o ping de keep-alive do
# Postgres está registrado). Substitui lib/tasks/student_emails.rake.
class WeeklyReminderJob < ApplicationJob
  queue_as :default

  def perform
    return unless Date.current.monday?

    User.where(role: "student", weekly_reminder_email: true).find_each do |student|
      next if student.level.blank?

      levels = StudentMailer.notifiable_levels_for_activity(student.level)
                             .push(student.level)
                             .uniq

      completed_ids = QuizAttempt.where(user_id: student.id).pluck(:activity_id)

      pending = Activity.published
                         .where(level: levels)
                         .where.not(id: completed_ids)
                         .order(created_at: :desc)
                         .to_a

      featured = []
      if pending.count < 3
        featured = Activity.published
                            .where(level: levels)
                            .joins(:activity_ratings)
                            .group("activities.id")
                            .having("COUNT(activity_ratings.id) >= 1")
                            .order("AVG(activity_ratings.stars) DESC")
                            .where.not(id: completed_ids + pending.map(&:id))
                            .limit(3)
                            .to_a
      end

      next if pending.empty? && featured.empty?

      StudentMailer.weekly_reminder(student, pending, featured).deliver_later

      push_body = case student.language
                  when "fr" then "Vos exercices de la semaine vous attendent 🌿"
                  when "en" then "Your exercises for this week are ready 🌿"
                  else           "Seus exercícios desta semana estão esperando 🌿"
                  end

      PushNotificationService.send_to_user(
        student,
        title: "Practice-BR",
        body:  push_body,
        url:   Rails.application.routes.url_helpers.student_dashboard_url(
                 host: Rails.application.config.action_mailer.default_url_options[:host]
               )
      )
    end
  end
end
