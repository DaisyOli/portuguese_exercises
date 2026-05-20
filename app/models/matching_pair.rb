class MatchingPair < ApplicationRecord
  belongs_to :column_matching

  validates :left_item, presence: true
  validates :right_item, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 }
end
