FactoryBot.define do
  factory :activity_rating do
    association :user, factory: [:user, :student]
    association :activity
    stars { 5 }
  end
end
