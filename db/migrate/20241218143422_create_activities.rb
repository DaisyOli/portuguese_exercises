class CreateActivities < ActiveRecord::Migration[7.1]
  def change
    create_table :activities do |t|
      t.string :title
      t.text :description
      t.string :content_type
      t.string :content_url
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
