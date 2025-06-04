FactoryBot.define do
  factory :activity do
    title { Faker::Educator.course_name }
    description { Faker::Lorem.paragraph }
    level { Activity.levels.keys.sample }
    
    # Association com teacher (User)
    association :teacher, factory: [:user, :teacher]
    
    trait :A1 do
      level { 'A1' }
    end
    
    trait :A2 do
      level { 'A2' }
    end
    
    trait :B1 do
      level { 'B1' }
    end
    
    trait :B2 do
      level { 'B2' }
    end
    
    trait :C1 do
      level { 'C1' }
    end
  end
end 