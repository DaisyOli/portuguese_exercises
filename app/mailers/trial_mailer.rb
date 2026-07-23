class TrialMailer < ApplicationMailer
  INTERNAL_EMAIL = "contato@practicebr.com".freeze

  def welcome_email(user, reset_token)
    @user        = user
    @reset_token = reset_token
    @login_url   = edit_user_password_url(reset_password_token: reset_token, host: default_url_options[:host], protocol: default_url_options[:protocol] || "https")
    @expires_at  = user.trial_expires_at

    mail(to: user.email, subject: "Seu acesso de teste à Practice-BR está pronto")
  end

  def notification_email(user)
    @user       = user
    @expires_at = user.trial_expires_at

    mail(to: INTERNAL_EMAIL, subject: "Novo trial cadastrado: #{user.email} (#{user.level})")
  end

  def reminder_email(user)
    @user          = user
    @expires_at    = user.trial_expires_at
    @days_since    = ((Time.current - user.created_at) / 1.day).round
    @days_left     = [((@expires_at - Time.current) / 1.day).ceil, 0].max
    @login_url     = new_user_session_url(host: default_url_options[:host], protocol: default_url_options[:protocol] || "https")

    mail(to: user.email, subject: "Faltam #{@days_left} #{@days_left == 1 ? 'dia' : 'dias'} para o fim do seu teste na Practice-BR")
  end
end
