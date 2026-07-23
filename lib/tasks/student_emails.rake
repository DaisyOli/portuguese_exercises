namespace :student_emails do
  desc "Dispara manualmente o WeeklyReminderJob (o agendamento real é o cron do GoodJob, toda segunda)"
  task weekly_reminder: :environment do
    WeeklyReminderJob.perform_now
    puts "[student_emails:weekly_reminder] WeeklyReminderJob executado."
  end
end
