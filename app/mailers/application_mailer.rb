class ApplicationMailer < ActionMailer::Base
  default from: "Exercise App <no-reply@exerciseapp.com.br>", 
          reply_to: "suporte@exerciseapp.com.br"
  layout "mailer"
  
  def self.configure_headers(headers)
    headers.merge!({
      'X-MC-AutoText' => 'true',
      'X-Priority' => '3',
      'X-Mailer' => 'Exercise App Mailer',
      'Importance' => 'Normal',
      'Message-ID' => "<#{SecureRandom.uuid}@exerciseapp.com.br>",
      'Precedence' => 'Bulk'
    })
  end
end
