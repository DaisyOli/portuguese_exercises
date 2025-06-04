FactoryBot.define do
  factory :quiz_attempt do
    association :user
    association :activity
    score { rand(60.0..100.0).round(2) }
    submitted_at { Time.current }
    
    results do
      {
        activity_id: activity.id,
        results: {
          "1" => {
            is_correct: true,
            question_text: "Qual é a capital do Brasil?",
            question_type: "multiple_choice",
            given_answer: "Brasília",
            correct_answer: "Brasília"
          }
        },
        score: score,
        total_correct: 1,
        total_questions: 1,
        submitted_at: submitted_at
      }
    end
    
    trait :perfect_score do
      score { 100.0 }
    end
    
    trait :failing_score do
      score { rand(0.0..50.0).round(2) }
    end
    
    trait :with_detailed_results do
      transient do
        questions_count { 3 }
        correct_answers { 2 }
      end
      
      score { (correct_answers.to_f / questions_count * 100).round(2) }
      
      results do
        results_hash = {}
        questions_count.times do |i|
          results_hash[(i + 1).to_s] = {
            is_correct: i < correct_answers,
            question_text: "Questão #{i + 1}?",
            question_type: "multiple_choice",
            given_answer: i < correct_answers ? "Resposta Correta" : "Resposta Errada",
            correct_answer: "Resposta Correta"
          }
        end
        
        {
          activity_id: activity.id,
          results: results_hash,
          score: score,
          total_correct: correct_answers,
          total_questions: questions_count,
          submitted_at: submitted_at
        }
      end
    end
  end
end 