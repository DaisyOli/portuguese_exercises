class Suggestion < ApplicationRecord
  belongs_to :activity
  
  validates :content, presence: true, length: { minimum: 10, maximum: 1000 }
end 