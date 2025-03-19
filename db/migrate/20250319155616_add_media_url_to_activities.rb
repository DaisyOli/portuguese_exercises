class AddMediaUrlToActivities < ActiveRecord::Migration[7.1]
  def change
    add_column :activities, :media_url, :string
  end
end
