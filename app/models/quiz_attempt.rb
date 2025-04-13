class QuizAttempt < ApplicationRecord
  belongs_to :user
  belongs_to :activity
  
  validates :score, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :results, presence: true
  
  # Definir quais campos resultados deve ter
  validates_each :results do |record, attr, value|
    unless value.is_a?(Hash) && value.key?("total_correct") && value.key?("total_questions")
      record.errors.add(attr, "deve conter total_correct e total_questions")
    end
  end
  
  before_create :set_submitted_at
  after_create :clear_user_attempts_cache
  
  # Métodos de conveniência para acessar informações dos resultados
  def total_correct
    results["total_correct"] if results
  end
  
  def total_questions
    results["total_questions"] if results
  end
  
  def correct_percentage
    score || 0
  end
  
  def question_results
    results["results"] if results
  end
  
  private
  
  def set_submitted_at
    self.submitted_at ||= Time.current
  end
  
  def clear_user_attempts_cache
    Rails.cache.delete_matched("best_attempts/#{user_id}*")
  end
end
