class AddWeeklyReminderEmailToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :weekly_reminder_email, :boolean, default: false, null: false
  end
end
