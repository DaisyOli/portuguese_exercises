class AddExplanationTextToActivities < ActiveRecord::Migration[7.1]
  def change
    add_column :activities, :explanation_text, :text
  end
end
