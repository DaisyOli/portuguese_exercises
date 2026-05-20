class CreateMatchingPairs < ActiveRecord::Migration[7.1]
  def change
    create_table :matching_pairs do |t|
      t.references :column_matching, null: false, foreign_key: true
      t.string :left_item, null: false
      t.string :right_item, null: false
      t.integer :position, null: false, default: 1

      t.timestamps
    end
  end
end
