class AdminMailer < ApplicationMailer
  ADMIN_EMAIL = "contato@practicebr.com".freeze

  def new_teacher_notification(teacher)
    @teacher = teacher

    mail(to: ADMIN_EMAIL, subject: "Novo professor na Practice-BR: #{teacher.display_name}")
  end
end
