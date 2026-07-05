class CreateVideoSuggestions < ActiveRecord::Migration[7.1]
  def change
    create_table :video_suggestions do |t|
      t.string :youtube_url
      t.string :title
      t.string :thumbnail_url
      t.string :channel_name
      t.string :topic
      t.string :level_hint
      t.string :status, default: 'pending', null: false
      t.text :transcript
      t.integer :activity_id
      t.integer :teacher_id

      t.timestamps
    end
  end
end
