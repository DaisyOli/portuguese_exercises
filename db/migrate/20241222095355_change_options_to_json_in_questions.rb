class ChangeOptionsToJsonInQuestions < ActiveRecord::Migration[7.0]
  def change
    change_column :questions, :options, :json, using: 'options::json'
  end
end
