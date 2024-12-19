class AddLevelToActivities < ActiveRecord::Migration[7.1]
  def change
    add_column :activities, :level, :string
  end
end
