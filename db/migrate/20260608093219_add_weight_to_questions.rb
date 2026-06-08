class AddWeightToQuestions < ActiveRecord::Migration[7.1]
  def change
    add_column :questions, :weight, :integer, default: 1, null: false
  end
end
