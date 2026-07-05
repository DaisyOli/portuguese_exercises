class AddExplanationIsTranscriptToActivities < ActiveRecord::Migration[7.1]
  def change
    add_column :activities, :explanation_is_transcript, :boolean, default: false
  end
end
