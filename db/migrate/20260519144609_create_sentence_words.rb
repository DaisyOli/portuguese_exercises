class CreateSentenceWords < ActiveRecord::Migration[7.1]
  def change
    create_table :sentence_words do |t|
      t.references :sentence_ordering, null: false, foreign_key: true
      t.string :word, null: false
      t.integer :correct_position, null: false
      t.integer :display_position, null: false

      t.timestamps
    end
    add_index :sentence_words, [:sentence_ordering_id, :correct_position], unique: true, name: 'index_sentence_words_on_ordering_and_position'
  end
end
