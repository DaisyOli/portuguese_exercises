require "test_helper"
require "minitest/mock"

class PushNotificationServiceTest < ActiveSupport::TestCase
  setup do
    @student = users(:student_pt)
    @student.push_subscriptions.create!(
      endpoint:   "https://push.example.com/sub_test",
      p256dh_key: "p256dh_value",
      auth_key:   "auth_value"
    )
    @args = { title: "Practice-BR", body: "Novo exercício disponível!", url: "https://practicebr.com" }
  end

  test "não chama WebPush quando VAPID_PUBLIC_KEY não está configurado" do
    original = ENV.delete("VAPID_PUBLIC_KEY")
    called = false
    WebPush.stub(:payload_send, ->(*) { called = true }) do
      PushNotificationService.send_to_user(@student, **@args)
    end
    assert_not called, "WebPush não deve ser chamado sem VAPID_PUBLIC_KEY"
  ensure
    ENV["VAPID_PUBLIC_KEY"] = original if original
  end

  test "remove subscription expirada automaticamente sem levantar exceção" do
    original = ENV["VAPID_PUBLIC_KEY"]
    ENV["VAPID_PUBLIC_KEY"] = "fake_vapid_public_key"

    # .allocate cria instância sem chamar initialize (que exige response e host)
    expired = WebPush::ExpiredSubscription.allocate
    WebPush.stub(:payload_send, ->(*) { raise expired }) do
      assert_difference "@student.reload.push_subscriptions.count", -1 do
        PushNotificationService.send_to_user(@student, **@args)
      end
    end
  ensure
    ENV["VAPID_PUBLIC_KEY"] = original
  end

  test "captura erros inesperados sem levantar exceção" do
    original = ENV["VAPID_PUBLIC_KEY"]
    ENV["VAPID_PUBLIC_KEY"] = "fake_vapid_public_key"

    WebPush.stub(:payload_send, ->(*) { raise "Timeout de rede" }) do
      assert_nothing_raised do
        PushNotificationService.send_to_user(@student, **@args)
      end
    end
  ensure
    ENV["VAPID_PUBLIC_KEY"] = original
  end

  test "não explode quando usuário não tem subscriptions" do
    student_sem_sub = users(:student_fr)
    original = ENV["VAPID_PUBLIC_KEY"]
    ENV["VAPID_PUBLIC_KEY"] = "fake_vapid_public_key"

    assert_nothing_raised do
      PushNotificationService.send_to_user(student_sem_sub, **@args)
    end
  ensure
    ENV["VAPID_PUBLIC_KEY"] = original
  end
end
