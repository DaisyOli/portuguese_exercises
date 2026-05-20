class SentenceOrdering < ApplicationRecord
  belongs_to :activity
  has_many :sentence_words, dependent: :destroy

  validates :sentence, presence: true, length: { minimum: 3 }

  after_create :process_words!
  before_update :reprocess_words!, if: :sentence_changed?

  def shuffled_words
    sentence_words.order(:display_position)
  end

  def check_order(word_ids_in_order)
    words = sentence_words.to_a
    return false if word_ids_in_order.length != words.length

    word_ids_in_order.each_with_index.all? do |word_id, index|
      word = words.find { |w| w.id == word_id.to_i }
      word&.correct_position == index + 1
    end
  end

  private

  def process_words!
    words = sentence.split(/\s+/)
    positions = (1..words.length).to_a.shuffle

    words.each_with_index do |word_text, i|
      sentence_words.create!(
        word: word_text,
        correct_position: i + 1,
        display_position: positions[i]
      )
    end
  end

  def reprocess_words!
    sentence_words.destroy_all
    process_words!
  end
end
