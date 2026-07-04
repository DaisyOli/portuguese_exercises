class AddPublishedAtToActivities < ActiveRecord::Migration[7.1]
  def up
    add_column :activities, :published_at, :datetime
    execute "UPDATE activities SET published_at = updated_at WHERE draft = false"
  end

  def down
    remove_column :activities, :published_at
  end
end
