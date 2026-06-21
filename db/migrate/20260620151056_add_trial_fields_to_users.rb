class AddTrialFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :trial_activities_used, :integer, default: 0, null: false
    add_column :users, :trial_expires_at, :datetime
  end
end
