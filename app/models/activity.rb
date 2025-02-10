class Activity < ApplicationRecord
  belongs_to :teacher, class_name: 'User'
  has_many :questions, dependent: :destroy

  validates :title, presence: true
  validates :description, presence: true
  validates :level, presence: true
  
  enum level: {
    'A1': 0,
    'A2': 1,
    'B1': 2,
    'B2': 3,
    'C1': 4
  }
end
