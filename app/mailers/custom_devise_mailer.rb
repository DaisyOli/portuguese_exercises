class CustomDeviseMailer < Devise::Mailer
  helper :application
  include Devise::Controllers::UrlHelpers
  default template_path: 'devise/mailer'
  
  # Adiciona cabeçalhos importantes para evitar que emails caiam no spam
  def headers_for(action, opts)
    headers = super
    headers.merge!({
      'X-MC-AutoText' => 'true',
      'X-Priority' => '3',
      'X-Mailer' => 'PracticePT Mailer',
      'Importance' => 'Normal',
      'Message-ID' => "<#{SecureRandom.uuid}@exerciseapp.com.br>",
      'Precedence' => 'Bulk'
    })
    headers
  end
  
  # Sobrescreve o método de recuperação de senha
  def reset_password_instructions(record, token, opts = {})
    @subject = "Recuperação de senha - Exercise App"
    @name = record.name if record.respond_to?(:name)
    @token = token
    devise_mail(record, :reset_password_instructions, opts.merge(subject: @subject))
  end
end
