class AddCorrectAnswersToQuestions < ActiveRecord::Migration[7.1]
  def change
    add_column :questions, :correct_answers, :jsonb, default: []
  end
end
