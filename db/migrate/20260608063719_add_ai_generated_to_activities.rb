class AddAiGeneratedToActivities < ActiveRecord::Migration[7.1]
  def change
    add_column :activities, :ai_generated, :boolean, default: false, null: false
  end
end
