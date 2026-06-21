class ApplicationMailer < ActionMailer::Base
  default from: "Practice-BR <no-reply@practicebr.com>",
          reply_to: "contato@practicebr.com"
  layout "mailer"
  
  def self.configure_headers(headers)
    headers.merge!({
      'X-MC-AutoText' => 'true',
      'X-Priority' => '3',
      'X-Mailer' => 'Exercise App Mailer',
      'Importance' => 'Normal',
      'Message-ID' => "<#{SecureRandom.uuid}@practicebr.com>",
      'Precedence' => 'Bulk'
    })
  end
end
