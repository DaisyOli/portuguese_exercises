class AddTeacherCommentsToQuizAttempts < ActiveRecord::Migration[7.1]
  def change
    add_column :quiz_attempts, :teacher_comments, :jsonb, default: {}, null: false
  end
end
