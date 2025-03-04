class Activity < ApplicationRecord
  belongs_to :teacher, class_name: 'User'
  has_many :questions, dependent: :destroy

  validates :title, presence: true
  validates :description, presence: true
  validates :level, presence: true
  
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
end
