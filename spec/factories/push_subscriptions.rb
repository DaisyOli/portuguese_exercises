FactoryBot.define do
  factory :push_subscription do
    association :user
    sequence(:endpoint) { |n| "https://push.example.com/sub/#{n}" }
    p256dh_key { "p256dh-key" }
    auth_key   { "auth-key" }
  end
end
