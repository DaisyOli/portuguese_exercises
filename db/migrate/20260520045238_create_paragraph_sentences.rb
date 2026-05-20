class CreateParagraphSentences < ActiveRecord::Migration[7.1]
  def change
    create_table :paragraph_sentences do |t|
      t.references :paragraph_ordering, null: false, foreign_key: true
      t.text :sentence, null: false
      t.integer :correct_position, null: false
      t.integer :display_position, null: false

      t.timestamps
    end
    add_index :paragraph_sentences, [:paragraph_ordering_id, :correct_position], unique: true, name: 'index_paragraph_sentences_on_ordering_and_position'
  end
end
