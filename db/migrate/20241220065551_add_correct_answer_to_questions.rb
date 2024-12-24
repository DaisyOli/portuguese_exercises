class AddCorrectAnswerToQuestions < ActiveRecord::Migration[7.1]
  def change
    add_column :questions, :correct_answer, :string
  end
end
