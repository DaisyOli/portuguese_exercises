class UpdateForeignKeyConstraints < ActiveRecord::Migration[7.1]
  def change
    # Remove a chave estrangeira existente
    remove_foreign_key :questions, :activities rescue nil
    
    # Adiciona a chave estrangeira com a opção ON DELETE CASCADE
    add_foreign_key :questions, :activities, on_delete: :cascade
  end
end
