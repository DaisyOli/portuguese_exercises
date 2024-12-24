class ChangeOptionsColumnTypeToJson < ActiveRecord::Migration[6.1]
  def change
    change_column :questions, :options, :json, using: 'options::json'
  end
end
