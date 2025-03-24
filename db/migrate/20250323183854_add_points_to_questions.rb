class AddPointsToQuestions < ActiveRecord::Migration[7.1]
  def change
    add_column :questions, :points, :integer, default: 10
  end
end
