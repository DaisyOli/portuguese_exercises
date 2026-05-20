class AddSentenceWordsCountToSentenceOrderings < ActiveRecord::Migration[7.1]
  def change
    add_column :sentence_orderings, :sentence_words_count, :integer, default: 0, null: false
    SentenceOrdering.find_each do |ordering|
      SentenceOrdering.reset_counters(ordering.id, :sentence_words)
    end
  end
end
