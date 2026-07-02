require "test_helper"

class PushSubscriptionTest < ActiveSupport::TestCase
  def build_sub(overrides = {})
    PushSubscription.new({
      user:       users(:student_pt),
      endpoint:   "https://fcm.googleapis.com/fcm/send/test_abc",
      p256dh_key: "p256dh_placeholder",
      auth_key:   "auth_placeholder"
    }.merge(overrides))
  end

  test "é válido com todos os atributos" do
    assert build_sub.valid?
  end

  test "endpoint é obrigatório" do
    sub = build_sub(endpoint: nil)
    assert_not sub.valid?
    assert sub.errors[:endpoint].any?, "deve ter erro de validação no endpoint"
  end

  test "endpoint deve ser único por usuário" do
    endpoint = "https://fcm.googleapis.com/fcm/send/duplicado"
    users(:student_pt).push_subscriptions.create!(
      endpoint: endpoint, p256dh_key: "k1", auth_key: "a1"
    )
    sub = build_sub(endpoint: endpoint)
    assert_not sub.valid?
    assert sub.errors[:endpoint].any?, "deve ter erro de unicidade no endpoint"
  end

  test "mesmo endpoint é permitido para usuários diferentes" do
    endpoint = "https://fcm.googleapis.com/fcm/send/compartilhado"
    users(:student_pt).push_subscriptions.create!(
      endpoint: endpoint, p256dh_key: "k1", auth_key: "a1"
    )
    sub = build_sub(endpoint: endpoint, user: users(:student_fr))
    assert sub.valid?
  end

  test "pertence a um usuário" do
    sub = build_sub
    assert_equal users(:student_pt), sub.user
  end
end
