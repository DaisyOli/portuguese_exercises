class AddDraftToActivities < ActiveRecord::Migration[7.1]
  def change
    add_column :activities, :draft, :boolean, default: false, null: false
  end
end
