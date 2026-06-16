class QuizAttempt < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :activity
  
  validates :score, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :results, presence: true
  
  # Definir quais campos resultados deve ter
  validates_each :results do |record, attr, value|
    unless value.is_a?(Hash) && value.key?("score") && value.key?("total_questions")
      record.errors.add(attr, "deve conter score e total_questions")
    end
  end
  
  scope :completed, -> { where.not(submitted_at: nil) }
  scope :for_user, ->(user) { where(user: user) }

  before_create :set_submitted_at
  after_commit :clear_user_attempts_cache, if: :user_id?

  def total_correct
    results["total_correct"] if results
  end
  
  def total_questions
    results["total_questions"] if results
  end
  
  def correct_percentage
    score || 0
  end

  def passed?
    score.to_i >= 60
  end
  
  def question_results
    results["results"] if results
  end

  def open_ended_results
    return [] unless results&.dig("results").is_a?(Hash)
    results["results"].select { |_k, v| v.is_a?(Hash) && v["question_type"] == "open_ended" }
  end

  def teacher_comment_for(question_id)
    (teacher_comments || {})["question_#{question_id}"].presence
  end

  def normalized_results(questions = {})
    data = results.dup

    unless data.key?("total_questions")
      if data.values.any? { |v| v.is_a?(Hash) && v["is_correct"] }
        data = {
          "activity_id" => activity_id,
          "results"     => data,
          "score"       => score,
          "total_correct"   => data.values.count { |r| r["is_correct"] },
          "total_questions" => data.size,
          "submitted_at"    => submitted_at
        }
      else
        data = {
          "activity_id"     => activity_id,
          "results"         => {},
          "score"           => score.to_i,
          "total_correct"   => 0,
          "total_questions" => 0,
          "submitted_at"    => submitted_at || Time.current
        }
      end
    end

    data["results"] = {} unless data["results"].is_a?(Hash)

    data["results"].each do |question_id, result|
      question = questions[question_id.to_i]
      if question
        result["question_text"]   ||= question.content
        result["question_type"]   ||= question.question_type
        result["correct_answer"]  ||= question.correct_answer
      end
      result["given_answer"] ||= I18n.t('quiz.not_answered')
    end

    data
  end
  
  # Método para limpar tentativas anônimas antigas (pode ser executado por um job)
  def self.clean_anonymous_attempts(older_than = 1.day)
    where(user_id: nil).where('created_at < ?', older_than.ago).delete_all
  end
  
  private
  
  def set_submitted_at
    self.submitted_at ||= Time.current
  end
  
  def clear_user_attempts_cache
    Rails.cache.delete_matched("best_attempts/#{user_id}*")
  end
end
