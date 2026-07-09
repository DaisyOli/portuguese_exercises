FactoryBot.define do
  factory :question do
    association :activity
    content { "Complete a frase: O gato _____ no telhado." }
    question_type { 'fill_in_blank' }
    correct_answer { 'está' }
    
    trait :multiple_choice do
      question_type { 'multiple_choice' }
      content { "Qual é a capital do Brasil?" }
      options { ["São Paulo", "Rio de Janeiro", "Brasília", "Salvador"] }
      correct_answer { "Brasília" }
    end
    
    trait :fill_in_blank do
      question_type { 'fill_in_blank' }
      content { "O _____ é um animal doméstico." }
      correct_answer { "gato" }
    end

    trait :open_ended do
      question_type { 'open_ended' }
      content { "Descreva a sua rotina matinal." }
      correct_answer { nil }
    end
  end
end 