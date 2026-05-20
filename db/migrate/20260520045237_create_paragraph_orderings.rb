class CreateParagraphOrderings < ActiveRecord::Migration[7.1]
  def change
    create_table :paragraph_orderings do |t|
      t.references :activity, null: false, foreign_key: true
      t.string :title
      t.text :instruction
      t.integer :display_order

      t.timestamps
    end
  end
end
