class ParagraphOrdering < ApplicationRecord
  belongs_to :activity
  has_many :paragraph_sentences, dependent: :destroy

  validates :activity, presence: true

  def shuffled_sentences
    paragraph_sentences.order(:display_position)
  end

  def check_order(sentence_ids_in_order)
    sentences = paragraph_sentences.to_a
    return false if sentence_ids_in_order.length != sentences.length

    sentence_ids_in_order.each_with_index.all? do |sentence_id, index|
      sentence = sentences.find { |s| s.id == sentence_id.to_i }
      sentence&.correct_position == index + 1
    end
  end

  def add_sentence(text)
    next_position = paragraph_sentences.maximum(:correct_position).to_i + 1
    paragraph_sentences.create!(
      sentence: text,
      correct_position: next_position,
      display_position: next_position
    )
    shuffle_display_positions!
  end

  private

  def shuffle_display_positions!
    sentences = paragraph_sentences.to_a
    shuffled = (1..sentences.length).to_a.shuffle
    sentences.each_with_index do |s, i|
      s.update_column(:display_position, shuffled[i])
    end
  end
end
