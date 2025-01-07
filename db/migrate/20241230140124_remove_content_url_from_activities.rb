class RemoveContentUrlFromActivities < ActiveRecord::Migration[7.1]
  def change
    remove_column :activities, :content_url, :string
  end
end
