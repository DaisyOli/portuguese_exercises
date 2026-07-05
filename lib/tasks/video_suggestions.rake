namespace :video_suggestions do
  desc "Gera sugestões diárias de vídeo para todos os professores (Heroku Scheduler: diariamente às 7h)"
  task generate: :environment do
    teachers = User.where(role: "teacher")
    if teachers.none?
      puts "Nenhum professor encontrado."
      next
    end

    teachers.each do |teacher|
      result = DailyVideoSuggestionsService.new(teacher: teacher).call
      if result[:skipped]
        puts "#{teacher.email}: já tem sugestões hoje (pulado)"
      elsif result[:success]
        puts "#{teacher.email}: #{result[:created]} sugestões criadas"
      else
        puts "#{teacher.email}: ERRO — #{result[:error]}"
      end
    end
  end
end
