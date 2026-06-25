class AddProfessionalTypeToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :professional_type, :string
  end
end
