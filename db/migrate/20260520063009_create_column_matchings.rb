class CreateColumnMatchings < ActiveRecord::Migration[7.1]
  def change
    create_table :column_matchings do |t|
      t.references :activity, null: false, foreign_key: true
      t.string :title
      t.string :instruction
      t.integer :display_order, default: 0

      t.timestamps
    end
  end
end
