class AddStatementToActivities < ActiveRecord::Migration[7.1]
  def change
    add_column :activities, :statement, :text
  end
end
