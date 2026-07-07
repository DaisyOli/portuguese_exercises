namespace :unsplash do
  desc "Busca imagens do Unsplash para atividades sem capa"
  task backfill: :environment do
    activities = Activity.where(unsplash_cover_url: nil)
                         .where(video_url: nil)
                         .reject { |a| a.image_file.attached? || a.media_url.present? }

    puts "#{activities.size} atividades sem capa encontradas."

    activities.each_with_index do |activity, i|
      query = [activity.title, activity.description].compact.join(" ").first(120)
      result = UnsplashService.new(query).call

      if result
        activity.update_columns(
          unsplash_cover_url:    result[:url],
          unsplash_cover_credit: "#{result[:photographer]} | Unsplash"
        )
        puts "✓ #{activity.title}"
      else
        puts "✗ #{activity.title} (sem resultado)"
      end

      sleep(0.5) if i % 10 == 9  # pausa a cada 10 para não estourar o rate limit
    end

    puts "Concluído."
  end
end
