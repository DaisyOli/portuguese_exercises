namespace :student_emails do
  desc "Envia lembrete semanal para alunos com weekly_reminder_email ativo (roda toda segunda)"
  task weekly_reminder: :environment do
    unless Date.today.monday?
      puts "Hoje não é segunda-feira — nada enviado."
      next
    end

    sent = 0

    User.where(role: "student", weekly_reminder_email: true).find_each do |student|
      next unless student.level.present?

      levels = StudentMailer.notifiable_levels_for_activity(student.level)
                            .push(student.level)
                            .uniq

      completed_ids = QuizAttempt.where(user_id: student.id).pluck(:activity_id)

      pending = Activity.published
                        .where(level: levels)
                        .where.not(id: completed_ids)
                        .order(created_at: :desc)

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
      end

      next if pending.empty? && featured.empty?

      StudentMailer.weekly_reminder(student, pending, featured).deliver_later

      push_body = student.language == "fr" ? "Vos exercices de la semaine vous attendent 🌿" :
                  student.language == "en" ? "Your exercises for this week are ready 🌿" :
                                             "Seus exercícios desta semana estão esperando 🌿"
      PushNotificationService.send_to_user(
        student,
        title: "Practice-BR",
        body:  push_body,
        url:   Rails.application.routes.url_helpers.student_dashboard_url(
                 host: Rails.application.config.action_mailer.default_url_options[:host]
               )
      )
      sent += 1
    end

    puts "Lembretes enviados: #{sent}"
  end
end
