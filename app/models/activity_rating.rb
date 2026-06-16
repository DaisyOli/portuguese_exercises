class ActivityRating < ApplicationRecord
  belongs_to :user
  belongs_to :activity

  validates :stars, presence: true, inclusion: { in: 1..5 }
  validates :user_id, uniqueness: { scope: :activity_id, message: "já avaliou esta atividade" }
  validates :comment, length: { maximum: 500 }
end
