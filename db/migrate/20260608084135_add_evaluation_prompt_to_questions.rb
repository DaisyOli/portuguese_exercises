class AddEvaluationPromptToQuestions < ActiveRecord::Migration[7.1]
  def change
    add_column :questions, :evaluation_prompt, :text
  end
end
