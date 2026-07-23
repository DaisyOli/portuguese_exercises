class AddInactivityNudgeSentAtToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :inactivity_nudge_sent_at, :datetime
  end
end
