FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { 'password123' }
    password_confirmation { 'password123' }
    role { 'student' }
    language { 'pt' }

    trait :teacher do
      role { 'teacher' }
    end

    trait :student do
      role { 'student' }
    end

    trait :english do
      language { 'en' }
    end

    trait :french do
      language { 'fr' }
    end

    trait :trial do
      role                  { 'trial' }
      level                 { 'B1' }
      trial_expires_at      { 7.days.from_now }
      trial_activities_used { 0 }
    end

    trait :admin do
      role  { 'teacher' }
      admin { true }
    end
  end
end
