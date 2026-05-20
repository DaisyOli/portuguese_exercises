class ColumnMatching < ApplicationRecord
  belongs_to :activity
  has_many :matching_pairs, dependent: :destroy

  validates :activity, presence: true

  def shuffled_pairs
    matching_pairs.order(:position).to_a.shuffle
  end

  def check_answer(answer_string)
    pairs = matching_pairs.to_a
    return false if answer_string.blank? || pairs.empty?

    given = answer_string.split(',').each_with_object({}) do |entry, hash|
      left_id, right_id = entry.split(':')
      hash[left_id] = right_id
    end

    return false if given.size != pairs.size

    pairs.all? { |pair| given[pair.id.to_s] == pair.id.to_s }
  end

  def add_pair(left_item, right_item)
    next_position = matching_pairs.maximum(:position).to_i + 1
    matching_pairs.create!(left_item: left_item, right_item: right_item, position: next_position)
  end
end
