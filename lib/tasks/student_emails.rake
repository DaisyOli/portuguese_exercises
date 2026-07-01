namespace :student_emails do
  desc "Envia lembrete semanal para alunos com weekly_reminder_email ativo (roda toda segunda)"
  task weekly_reminder: :environment do
    unless Date.today.monday?
      puts "Hoje não é segunda-feira — nada enviado."
      next
    end

    sent = 0

    User.where(role: "student", weekly_reminder_email: true).find_each do |student|
      next unless student.invited_by_id.present?

      teacher = User.find_by(id: student.invited_by_id)
      next unless teacher

      completed_ids = QuizAttempt.where(user_id: student.id)
                                 .joins(:activity)
                                 .where(activities: { draft: false })
                                 .pluck(:activity_id)

      levels = StudentMailer.notifiable_levels_for_activity(student.level)
                            .push(student.level)
                            .uniq

      pending = teacher.activities
                       .where(draft: false, level: levels)
                       .where.not(id: completed_ids)
                       .order(created_at: :desc)

      next if pending.empty?

      StudentMailer.weekly_reminder(student, pending).deliver_later
      sent += 1
    end

    puts "Lembretes enviados: #{sent}"
  end
end
