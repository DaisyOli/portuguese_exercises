namespace :activities do
  desc "Gera N atividades por IA (COUNT=5 rake activities:generate_daily)"
  task generate_daily: :environment do
    require Rails.root.join("lib/activity_prompt_templates")

    count = ENV.fetch("COUNT", 1).to_i
    teacher = User.find_by(email: "daisy.oliani@gmail.com")
    unless teacher
      Rails.logger.error "[ActivityAgent] Professora não encontrada — abortando."
      next
    end

    count.times do |i|
      Rails.logger.info "[ActivityAgent] Gerando #{i + 1}/#{count}..."

      target = { "A1" => 30, "A2" => 30, "B1" => 30, "B2" => 20 }
      current = Activity.where(teacher: teacher, ai_generated: true, draft: false).group(:level).count

      level = target
        .map    { |lvl, goal| [lvl, goal - current.fetch(lvl, 0)] }
        .select { |_, gap| gap > 0 }
        .max_by { |_, gap| gap }
        &.first

      if level.nil?
        Rails.logger.info "[ActivityAgent] Meta atingida em todos os níveis!"
        break
      end

      existing_count = Activity.where(teacher: teacher, ai_generated: true, level: level).count
      prompt = ActivityPromptTemplates.pick(level, existing_count: existing_count)
      Rails.logger.info "[ActivityAgent] Nível: #{level} (existing: #{existing_count}) | Prompt: #{prompt[0..80]}..."

      result = ActivityGenerationService.new(prompt: prompt, teacher: teacher).call

      if result[:success]
        activity = result[:activity]
        Rails.logger.info "[ActivityAgent] ✅ '#{activity.title}'"
        AdminMailer.draft_ready(activity).deliver_now
      else
        Rails.logger.error "[ActivityAgent] ❌ Falha (#{i + 1}/#{count}): #{result[:error]}"
        AdminMailer.draft_generation_failed(level, result[:error]).deliver_now
      end

      sleep 3 if i < count - 1
    end

    Rails.logger.info "[ActivityAgent] Concluído."
  end
end
