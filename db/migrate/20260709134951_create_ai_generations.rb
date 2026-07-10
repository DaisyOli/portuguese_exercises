class CreateAiGenerations < ActiveRecord::Migration[7.1]
  # Rastreia gerações de atividade por IA que rodam em background
  # (a chamada à IA passava de 30s com transcrições longas e o Heroku
  # cortava a requisição com H12)
  def change
    create_table :ai_generations do |t|
      t.references :teacher, null: false, foreign_key: { to_table: :users }
      t.references :activity, null: true, foreign_key: true
      t.string :kind, null: false                  # "prompt" | "video"
      t.string :status, null: false, default: "queued"
      t.jsonb :request_params, null: false, default: {}
      t.text :error_message
      t.timestamps
    end
  end
end
