class AddVideoUrlToActivities < ActiveRecord::Migration[7.1]
  def change
    add_column :activities, :video_url, :string
  end
end
