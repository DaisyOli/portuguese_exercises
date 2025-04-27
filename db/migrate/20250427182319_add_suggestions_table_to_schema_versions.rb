class AddSuggestionsTableToSchemaVersions < ActiveRecord::Migration[7.1]
  def up
    # A tabela já existe, apenas registrando a migração
    # Este comando não faz nada se a tabela já existir
    unless connection.table_exists?(:suggestions)
      create_table :suggestions do |t|
        t.text :content
        t.references :activity, null: false, foreign_key: true
        t.timestamps
      end
    end
  end
  
  def down
    # Não fazer nada no rollback
  end
end
