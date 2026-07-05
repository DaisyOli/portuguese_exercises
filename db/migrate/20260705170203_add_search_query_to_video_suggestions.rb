class AddSearchQueryToVideoSuggestions < ActiveRecord::Migration[7.1]
  def change
    add_column :video_suggestions, :search_query, :string
  end
end
