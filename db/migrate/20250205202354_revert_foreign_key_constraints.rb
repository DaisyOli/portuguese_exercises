class RevertForeignKeyConstraints < ActiveRecord::Migration[7.1]
  def change
    # Remove a chave estrangeira com cascade
    remove_foreign_key :questions, :activities rescue nil
    
    # Adiciona a chave estrangeira normal
    add_foreign_key :questions, :activities
  end
end
