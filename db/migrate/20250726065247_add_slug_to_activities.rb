class AddSlugToActivities < ActiveRecord::Migration[7.1]
  def change
    add_column :activities, :slug, :string
    add_index :activities, :slug
  end
end
