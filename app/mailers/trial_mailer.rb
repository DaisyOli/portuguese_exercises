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
end
