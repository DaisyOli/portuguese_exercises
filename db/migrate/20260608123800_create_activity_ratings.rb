class CreateActivityRatings < ActiveRecord::Migration[7.1]
  def change
    create_table :activity_ratings do |t|
      t.references :user,     null: false, foreign_key: true
      t.references :activity, null: false, foreign_key: true
      t.integer    :stars,    null: false
      t.text       :comment

      t.timestamps
    end

    add_index :activity_ratings, [:user_id, :activity_id], unique: true
    add_check_constraint :activity_ratings, "stars >= 1 AND stars <= 5", name: "stars_range_check"
  end
end
