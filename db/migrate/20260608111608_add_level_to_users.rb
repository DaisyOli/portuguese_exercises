class AddLevelToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :level, :string
  end
end
