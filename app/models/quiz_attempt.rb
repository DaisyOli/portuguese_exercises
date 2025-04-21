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
  
  before_create :set_submitted_at
  after_commit :clear_user_attempts_cache, if: :user_id?
  
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
  
  # Método para limpar tentativas anônimas antigas (pode ser executado por um job)
  def self.clean_anonymous_attempts(older_than = 1.day)
    where(user_id: nil).where('created_at < ?', older_than.ago).delete_all
  end
  
  private
  
  def set_submitted_at
    self.submitted_at ||= Time.current
  end
  
  def clear_user_attempts_cache
    Rails.cache.delete_matched("best_attempts/#{user_id}*") if user_id.present?
  end
end
