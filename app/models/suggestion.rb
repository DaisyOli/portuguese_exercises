class Suggestion < ApplicationRecord
  belongs_to :activity
  
  validates :content, presence: true, length: { minimum: 3, maximum: 1000 }
end 