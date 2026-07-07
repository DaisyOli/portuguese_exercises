class AddUnsplashCoverToActivities < ActiveRecord::Migration[7.1]
  def change
    add_column :activities, :unsplash_cover_url, :string
    add_column :activities, :unsplash_cover_credit, :string
  end
end
