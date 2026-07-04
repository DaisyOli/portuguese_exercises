namespace :digest do
  desc "Envia digest semanal de atividades novas para alunos com lembrete ativado (roda toda segunda-feira)"
  task weekly: :environment do
    unless Date.today.monday?
      puts "[digest:weekly] Hoje não é segunda-feira — nada enviado."
      next
    end

    since = 7.days.ago
    sent  = 0
    skip  = 0

    User.where(role: "student", weekly_reminder_email: true).find_each do |student|
      next if student.level.blank?

      notifiable_levels = StudentMailer.notifiable_levels_for_activity(student.level)

      new_activities = Activity
        .where(draft: false, level: notifiable_levels)
        .where("published_at >= ?", since)
        .order(published_at: :desc)

      if new_activities.none?
        skip += 1
        next
      end

      StudentMailer.weekly_reminder(student, new_activities).deliver_later
      sent += 1
    end

    puts "[digest:weekly] Emails enfileirados: #{sent} | Sem novidades esta semana: #{skip}"
  end
end
