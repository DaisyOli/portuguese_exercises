class AddParagraphSentencesCountToParagraphOrderings < ActiveRecord::Migration[7.1]
  def change
    add_column :paragraph_orderings, :paragraph_sentences_count, :integer, default: 0, null: false
  end
end
