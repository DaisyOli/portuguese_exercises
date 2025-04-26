class Suggestion < ApplicationRecord
  belongs_to :activity
  
  validates :content, presence: true
end 