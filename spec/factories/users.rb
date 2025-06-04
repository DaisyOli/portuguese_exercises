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
  end
end 