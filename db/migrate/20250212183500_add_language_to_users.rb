class AddLanguageToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :language, :string, default: 'en'
    add_index :users, :language
  end
end 