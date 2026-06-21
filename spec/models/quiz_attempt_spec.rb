require 'rails_helper'

RSpec.describe QuizAttempt, type: :model do
  describe 'validations' do
    subject { build(:quiz_attempt) }
    
    it { should validate_presence_of(:score) }
    it { should validate_presence_of(:results) }
    it { should validate_numericality_of(:score).is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:score).is_less_than_or_equal_to(100) }
  end

  describe 'associations' do
    it { should belong_to(:user).optional }
    it { should belong_to(:activity) }
  end

  describe 'factory' do
    it 'creates valid quiz attempt by default' do
      attempt = create(:quiz_attempt)
      expect(attempt).to be_valid
      expect(attempt.score).to be_between(0, 100)
      expect(attempt.results).to be_a(Hash)
      expect(attempt.submitted_at).to be_present
      expect(attempt.user).to be_present
    end

    it 'creates quiz attempt with perfect score trait' do
      attempt = create(:quiz_attempt, :perfect_score)
      expect(attempt).to be_valid
      expect(attempt.score).to eq(100.0)
    end

    it 'creates quiz attempt with failing score trait' do
      attempt = create(:quiz_attempt, :failing_score)
      expect(attempt).to be_valid
      expect(attempt.score).to be_between(0, 50)
    end

    it 'creates quiz attempt with detailed results trait' do
      attempt = create(:quiz_attempt, :with_detailed_results, questions_count: 5, correct_answers: 3)
      expect(attempt).to be_valid
      expect(attempt.score).to eq(60.0)
      expect(attempt.total_questions).to eq(5)
      expect(attempt.total_correct).to eq(3)
    end
  end

  describe 'results validation' do
    it 'requires results to be a Hash' do
      attempt = build(:quiz_attempt, results: 'invalid')
      expect(attempt).not_to be_valid
      expect(attempt.errors[:results]).to include("deve conter score e total_questions")
    end

    it 'requires results to have score key' do
      attempt = build(:quiz_attempt, results: { "total_questions" => 5 })
      expect(attempt).not_to be_valid
      expect(attempt.errors[:results]).to include("deve conter score e total_questions")
    end

    it 'requires results to have total_questions key' do
      attempt = build(:quiz_attempt, results: { "score" => 85.0 })
      expect(attempt).not_to be_valid
      expect(attempt.errors[:results]).to include("deve conter score e total_questions")
    end

    it 'is valid when results has both required keys' do
      attempt = build(:quiz_attempt, results: { 
        "score" => 85.0, 
        "total_questions" => 10,
        "total_correct" => 8
      })
      expect(attempt).to be_valid
    end
  end

  describe 'score validation' do
    it 'rejects negative scores' do
      attempt = build(:quiz_attempt, score: -10)
      expect(attempt).not_to be_valid
      expect(attempt.errors[:score]).to include("tem de ser maior ou igual a 0")
    end

    it 'rejects scores over 100' do
      attempt = build(:quiz_attempt, score: 150)
      expect(attempt).not_to be_valid
      expect(attempt.errors[:score]).to include("tem de ser menor ou igual a 100")
    end

    it 'accepts score of 0' do
      attempt = build(:quiz_attempt, score: 0)
      expect(attempt).to be_valid
    end

    it 'accepts score of 100' do
      attempt = build(:quiz_attempt, score: 100)
      expect(attempt).to be_valid
    end

    it 'accepts decimal scores' do
      attempt = build(:quiz_attempt, score: 85.7)
      expect(attempt).to be_valid
    end
  end

  describe 'callbacks' do
    describe 'set_submitted_at' do
      it 'sets submitted_at before creation when nil' do
        attempt = build(:quiz_attempt, submitted_at: nil)
        expect { attempt.save! }.to change { attempt.submitted_at }.from(nil).to(be_present)
      end

      it 'preserves existing submitted_at' do
        specific_time = 1.hour.ago
        attempt = build(:quiz_attempt, submitted_at: specific_time)
        attempt.save!
        expect(attempt.submitted_at).to be_within(1.second).of(specific_time)
      end
    end

    describe 'clear_user_attempts_cache' do
      it 'clears cache after commit when user is present' do
        user = create(:user)
        attempt = create(:quiz_attempt, user: user)
        
        expect(Rails.cache).to receive(:delete_matched).with("best_attempts/#{user.id}*")
        attempt.update(score: 95.0)
      end
    end
  end

  describe 'convenience methods' do
    let(:attempt) do
      create(:quiz_attempt, 
        score: 80.0,
        results: {
          "score" => 80.0,
          "total_questions" => 10,
          "total_correct" => 8,
          "results" => {
            "1" => { "is_correct" => true },
            "2" => { "is_correct" => false }
          }
        }
      )
    end

    describe '#total_correct' do
      it 'returns total_correct from results' do
        expect(attempt.total_correct).to eq(8)
      end

      it 'returns nil when results is nil' do
        attempt_without_results = QuizAttempt.new
        expect(attempt_without_results.total_correct).to be_nil
      end
    end

    describe '#total_questions' do
      it 'returns total_questions from results' do
        expect(attempt.total_questions).to eq(10)
      end

      it 'returns nil when results is nil' do
        attempt_without_results = QuizAttempt.new
        expect(attempt_without_results.total_questions).to be_nil
      end
    end

    describe '#correct_percentage' do
      it 'returns score when present' do
        expect(attempt.correct_percentage).to eq(80.0)
      end

      it 'returns 0 when score is nil' do
        attempt_without_score = QuizAttempt.new
        expect(attempt_without_score.correct_percentage).to eq(0)
      end
    end

    describe '#question_results' do
      it 'returns results hash from results' do
        expect(attempt.question_results).to be_a(Hash)
        expect(attempt.question_results["1"]).to include("is_correct" => true)
      end

      it 'returns nil when results is nil' do
        attempt_without_results = QuizAttempt.new
        expect(attempt_without_results.question_results).to be_nil
      end
    end
  end

  describe 'user requirement' do
    it 'allows quiz attempts without user (for anonymous users)' do
      expect {
        QuizAttempt.create!(
          activity: create(:activity),
          score: 85.0,
          results: { "score" => 85.0, "total_questions" => 1 }
        )
      }.not_to raise_error
    end

    it 'is valid with a user' do
      attempt = build(:quiz_attempt, user: create(:user))
      expect(attempt).to be_valid
    end
  end

  describe 'integration with activity and user' do
    let(:activity) { create(:activity) }
    let(:user) { create(:user) }

    it 'belongs to an activity' do
      attempt = create(:quiz_attempt, activity: activity, user: user)
      expect(attempt.activity).to eq(activity)
    end

    it 'belongs to a user' do
      attempt = create(:quiz_attempt, activity: activity, user: user)
      expect(attempt.user).to eq(user)
    end

    it 'is destroyed when activity is destroyed' do
      attempt = create(:quiz_attempt, activity: activity, user: user)
      attempt_id = attempt.id
      
      expect { activity.destroy }.to change { QuizAttempt.count }.by(-1)
      expect(QuizAttempt.find_by(id: attempt_id)).to be_nil
    end

    it 'remains when user is destroyed (if configured for cascade)' do
      # Como user_id tem foreign key, vamos testar o comportamento atual
      attempt = create(:quiz_attempt, activity: activity, user: user)
      
      # Se há foreign key constraint, tentativa de delete deve falhar
      expect {
        user.delete # delete direto, sem callbacks
      }.to raise_error(ActiveRecord::InvalidForeignKey)
    end
  end

  describe 'real-world scenarios' do
    it 'stores complete quiz submission data' do
      activity = create(:activity)
      user = create(:user)
      
      attempt = create(:quiz_attempt,
        activity: activity,
        user: user,
        score: 75.0,
        results: {
          "activity_id" => activity.id,
          "score" => 75.0,
          "total_questions" => 4,
          "total_correct" => 3,
          "results" => {
            "1" => {
              "is_correct" => true,
              "question_text" => "O gato _____ no telhado.",
              "given_answer" => "está",
              "correct_answer" => "está"
            },
            "2" => {
              "is_correct" => false,
              "question_text" => "Qual é a capital do Brasil?",
              "given_answer" => "São Paulo",
              "correct_answer" => "Brasília"
            }
          }
        }
      )
      
      expect(attempt).to be_valid
      expect(attempt.total_questions).to eq(4)
      expect(attempt.total_correct).to eq(3)
      expect(attempt.score).to eq(75.0)
      expect(attempt.question_results).to be_a(Hash)
      expect(attempt.user).to eq(user)
      expect(attempt.activity).to eq(activity)
    end

    it 'handles multiple attempts by different users for same activity' do
      activity = create(:activity)
      user1 = create(:user, :student)
      user2 = create(:user, :student)

      attempt1 = create(:quiz_attempt, activity: activity, user: user1, score: 85.0)
      attempt2 = create(:quiz_attempt, activity: activity, user: user2, score: 92.0)

      expect(activity.quiz_attempts).to include(attempt1, attempt2)
      expect(user1.quiz_attempts).to include(attempt1)
      expect(user2.quiz_attempts).to include(attempt2)
    end
  end

  describe 'trial counter callback' do
    let(:trial_user) { create(:user, :trial, trial_activities_used: 0) }
    let(:activity)   { create(:activity) }

    it 'incrementa trial_activities_used ao criar nova tentativa' do
      expect {
        create(:quiz_attempt, user: trial_user, activity: activity)
      }.to change { trial_user.reload.trial_activities_used }.from(0).to(1)
    end

    it 'não incrementa ao atualizar uma tentativa existente' do
      attempt = create(:quiz_attempt, user: trial_user, activity: activity)
      expect {
        attempt.update!(score: 90)
      }.not_to change { trial_user.reload.trial_activities_used }
    end

    it 'não incrementa para usuário student' do
      student = create(:user, :student)
      expect {
        create(:quiz_attempt, user: student, activity: activity)
      }.not_to change { trial_user.reload.trial_activities_used }
    end

    it 'não incrementa para tentativa anônima (sem usuário)' do
      expect {
        create(:quiz_attempt, user: nil, activity: activity)
      }.not_to change { trial_user.reload.trial_activities_used }
    end
  end
end 