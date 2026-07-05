class AddDailyQuizTrackingToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :daily_quiz_count, :integer, default: 0, null: false
    add_column :users, :daily_quiz_date,  :date
  end
end
