class AddStartedAtToQuizAttempts < ActiveRecord::Migration[7.1]
  def change
    add_column :quiz_attempts, :started_at, :datetime
  end
end
