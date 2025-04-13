class CreateQuizAttempts < ActiveRecord::Migration[7.1]
  def change
    create_table :quiz_attempts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :activity, null: false, foreign_key: true
      t.float :score
      t.jsonb :results
      t.datetime :submitted_at

      t.timestamps
    end
  end
end
