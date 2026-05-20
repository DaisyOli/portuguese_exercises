class CreateSentenceOrderings < ActiveRecord::Migration[7.1]
  def change
    create_table :sentence_orderings do |t|
      t.references :activity, null: false, foreign_key: true
      t.text :sentence, null: false
      t.text :instruction
      t.integer :display_order

      t.timestamps
    end
  end
end
