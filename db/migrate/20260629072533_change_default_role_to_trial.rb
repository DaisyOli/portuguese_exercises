class ChangeDefaultRoleToTrial < ActiveRecord::Migration[7.1]
  def up
    change_column_default :users, :role, "trial"
  end

  def down
    change_column_default :users, :role, "student"
  end
end
