class RemoveConfirmableColumnsAndTightenActivities < ActiveRecord::Migration[7.1]
  # Dívidas do schema (Sprint 2):
  # - users: colunas do Devise :confirmable, módulo que nunca foi ativado
  #   (a migração 20250311070838 tinha o corpo vazio e não removeu nada)
  # - activities.teacher_id: o model valida presença, mas o banco permitia NULL
  def change
    remove_column :users, :confirmation_token, :string
    remove_column :users, :confirmed_at, :datetime
    remove_column :users, :confirmation_sent_at, :datetime
    remove_column :users, :unconfirmed_email, :string

    change_column_null :activities, :teacher_id, false
  end
end
