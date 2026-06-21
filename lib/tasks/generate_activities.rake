require Rails.root.join("lib/activity_prompt_templates")

namespace :activities do
  desc "Gera uma atividade por IA priorizando níveis com menos conteúdo publicado"
  task generate_daily: :environment do
    require Rails.root.join("lib/activity_prompt_templates")

    teacher = User.find_by(email: "daisy.oliani@gmail.com")
    unless teacher
      Rails.logger.error "[ActivityAgent] Professora não encontrada — abortando."
      next
    end

    target = { "A1" => 30, "A2" => 30, "B1" => 30, "B2" => 20 }
    current = Activity
      .where(teacher: teacher, ai_generated: true)
      .where(draft: false)
      .group(:level).count

    level = target
      .map  { |lvl, goal| [lvl, goal - current.fetch(lvl, 0)] }
      .select { |_, gap| gap > 0 }
      .max_by { |_, gap| gap }
      &.first

    if level.nil?
      Rails.logger.info "[ActivityAgent] Meta atingida em todos os níveis! Nada a gerar."
      next
    end

    prompt = ActivityPromptTemplates.pick(level)
    Rails.logger.info "[ActivityAgent] Nível selecionado: #{level} (gap: #{target[level] - current.fetch(level, 0)})"
    Rails.logger.info "[ActivityAgent] Prompt: #{prompt[0..100]}..."

    result = ActivityGenerationService.new(prompt: prompt, teacher: teacher).call

    if result[:success]
      activity = result[:activity]
      Rails.logger.info "[ActivityAgent] ✅ Atividade criada: '#{activity.title}' (#{activity.slug})"
      AdminMailer.draft_ready(activity).deliver_now
    else
      Rails.logger.error "[ActivityAgent] ❌ Falha: #{result[:error]}"
      AdminMailer.draft_generation_failed(level, result[:error]).deliver_now
    end
  end
end
