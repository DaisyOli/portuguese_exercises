class RemoveUserFromActivities < ActiveRecord::Migration[7.1]
  def change
    remove_reference :activities, :user, foreign_key: true
  end
end
