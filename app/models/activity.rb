class Activity < ApplicationRecord
  belongs_to :teacher, class_name: 'User'
  has_many :questions, dependent: :destroy

  validates :title, presence: true
  validates :description, presence: true
  validates :level, presence: true
  
  enum level: {
    iniciante: 0,
    intermediario: 1,
    avancado: 2
  }
end
