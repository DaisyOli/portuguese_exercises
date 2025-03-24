class QuizAttempt < ApplicationRecord
  belongs_to :user
  belongs_to :activity
  
  validates :user_id, presence: true
  validates :activity_id, presence: true
  validates :score, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  
  # Scope para obter a melhor tentativa de um usuário para uma atividade
  scope :best_attempt, -> (user_id, activity_id) { where(user_id: user_id, activity_id: activity_id).order(score: :desc).first }
  
  # Scope para obter todas as tentativas de um usuário
  scope :by_user, -> (user_id) { where(user_id: user_id).order(created_at: :desc) }
  
  # Scope para obter todas as tentativas para uma atividade
  scope :by_activity, -> (activity_id) { where(activity_id: activity_id).order(score: :desc) }
  
  # Calcular experiência baseada na pontuação
  def calculate_xp
    base_xp = 10
    # Bonus por pontuação alta
    score_bonus = (self.score / 10).to_i
    # Pontuação final
    base_xp + score_bonus
  end
  
  # Verificar se a tentativa foi concluída recentemente (nas últimas 24 horas)
  def completed_recently?
    completed_at && completed_at > 24.hours.ago
  end
  
  # Verificar se esta é a primeira tentativa bem-sucedida (mais de 70%)
  def first_success?
    score >= 70 && user.quiz_attempts.where(activity_id: activity_id).where('created_at < ?', created_at).count.zero?
  end
end
