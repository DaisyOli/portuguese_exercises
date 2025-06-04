class ChangeUserIdToOptionalInQuizAttempts < ActiveRecord::Migration[7.1]
  def change
    change_column_null :quiz_attempts, :user_id, true
  end
end
