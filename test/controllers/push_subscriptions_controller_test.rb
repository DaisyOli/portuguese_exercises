require "test_helper"

class PushSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @student = users(:student_pt)
    sign_in @student
  end

  # ── POST /push_subscriptions ────────────────────────────────────────────────

  test "POST create salva nova subscription" do
    assert_difference "PushSubscription.count", 1 do
      post push_subscriptions_path,
           params: {
             endpoint: "https://fcm.googleapis.com/fcm/send/novo123",
             keys: { p256dh: "p256dh_value", auth: "auth_value" }
           },
           as: :json
    end
    assert_response :ok
  end

  test "POST create é idempotente — atualiza keys se endpoint já existe" do
    @student.push_subscriptions.create!(
      endpoint:   "https://fcm.googleapis.com/fcm/send/existente",
      p256dh_key: "chave_antiga",
      auth_key:   "auth_antiga"
    )

    assert_no_difference "PushSubscription.count" do
      post push_subscriptions_path,
           params: {
             endpoint: "https://fcm.googleapis.com/fcm/send/existente",
             keys: { p256dh: "chave_nova", auth: "auth_nova" }
           },
           as: :json
    end
    assert_response :ok
    assert_equal "chave_nova", @student.push_subscriptions.last.p256dh_key
  end

  test "POST create requer autenticação" do
    sign_out @student
    post push_subscriptions_path,
         params: { endpoint: "https://fcm.example.com/sub", keys: { p256dh: "k", auth: "a" } },
         as: :json
    # JSON requests recebem 401, não redirect
    assert_includes [401, 302], response.status
  end

  # ── DELETE /push_subscriptions/:id ──────────────────────────────────────────

  test "DELETE destroy remove a subscription pelo endpoint" do
    sub = @student.push_subscriptions.create!(
      endpoint:   "https://fcm.googleapis.com/fcm/send/para_remover",
      p256dh_key: "key",
      auth_key:   "auth"
    )

    assert_difference "PushSubscription.count", -1 do
      delete push_subscription_path(sub),
             params: { endpoint: sub.endpoint },
             as: :json
    end
    assert_response :ok
  end

  test "DELETE destroy retorna ok mesmo se endpoint não existe" do
    sub = @student.push_subscriptions.create!(
      endpoint:   "https://fcm.googleapis.com/fcm/send/fantasma",
      p256dh_key: "key",
      auth_key:   "auth"
    )

    assert_nothing_raised do
      delete push_subscription_path(sub),
             params: { endpoint: "https://endpoint-inexistente.com" },
             as: :json
    end
    assert_response :ok
  end
end
