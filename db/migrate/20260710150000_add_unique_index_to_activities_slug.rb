class AddUniqueIndexToActivitiesSlug < ActiveRecord::Migration[7.1]
  # Gerações de IA simultâneas passavam juntas pela checagem de unicidade do
  # model (janela de corrida) e gravavam o mesmo slug — a atividade gêmea
  # ficava impossível de publicar. O índice único fecha a porta no banco;
  # antes, renomeia os gêmeos que já existirem (mantém o slug original na
  # atividade mais antiga).
  def up
    duplicated_slugs = select_values(<<~SQL)
      SELECT slug FROM activities GROUP BY slug HAVING COUNT(*) > 1
    SQL

    duplicated_slugs.each do |slug|
      twin_ids = select_values(
        "SELECT id FROM activities WHERE slug = #{quote(slug)} ORDER BY id ASC"
      )
      twin_ids.drop(1).each do |id|
        new_slug = "#{slug}-#{id}"
        say "slug duplicado: atividade #{id} renomeada para #{new_slug}"
        execute "UPDATE activities SET slug = #{quote(new_slug)} WHERE id = #{quote(id)}"
      end
    end

    remove_index :activities, :slug
    add_index :activities, :slug, unique: true
  end

  def down
    remove_index :activities, :slug
    add_index :activities, :slug
  end
end
