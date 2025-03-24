class CreateQuizAttempts < ActiveRecord::Migration[7.1]
  def change
    create_table :quiz_attempts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :activity, null: false, foreign_key: true
      t.float :score
      t.integer :xp_earned, default: 0
      t.integer :total_questions
      t.integer :correct_answers
      t.json :answers_data
      t.datetime :completed_at

      t.timestamps
    end
    
    add_index :quiz_attempts, [:user_id, :activity_id]
  end
end
