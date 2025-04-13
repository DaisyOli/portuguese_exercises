class Activity < ApplicationRecord
  belongs_to :teacher, class_name: 'User'
  has_many :questions, dependent: :destroy
  has_many :quiz_attempts, dependent: :destroy

  validates :title, presence: true
  validates :description, presence: true
  validates :level, presence: true
  
  after_commit :clear_cache
  
  enum level: {
    A1: 'A1',
    A2: 'A2',
    B1: 'B1',
    B2: 'B2',
    C1: 'C1'
  }

  def level_color_class
    case level
    when 'A1'
      'bg-info'        # Azul claro
    when 'A2'
      'bg-primary'     # Azul
    when 'B1'
      'bg-success'     # Verde
    when 'B2'
      'bg-warning'     # Amarelo
    when 'C1'
      'bg-danger'      # Vermelho
    else
      'bg-secondary'   # Cinza (caso padrão)
    end
  end
  
  private
  
  def clear_cache
    Rails.cache.delete_matched("activities*")
    Rails.cache.delete_matched("activity_questions/#{id}*")
    Rails.cache.delete_matched("activities_by_level*")
  end
end
