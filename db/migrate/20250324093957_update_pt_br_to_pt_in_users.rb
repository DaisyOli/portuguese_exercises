class UpdatePtBrToPtInUsers < ActiveRecord::Migration[7.1]
  def up
    User.where(language: 'pt-BR').update_all(language: 'pt')
  end

  def down
    # Não é necessário reverter, pois pt é um valor válido
  end
end
