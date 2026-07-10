# Gera uma atividade com IA em background (a partir de prompt ou de
# transcrição de vídeo). Fora do ciclo da requisição não existe o limite
# de 30s do Heroku, então transcrições longas deixam de estourar H12.
class AiActivityGenerationJob < ApplicationJob
  queue_as :default

  retry_on Anthropic::Errors::RateLimitError, Anthropic::Errors::APITimeoutError,
           Anthropic::Errors::APIConnectionError, wait: 15.seconds, attempts: 3 do |job, _error|
    generation = AiGeneration.find_by(id: job.arguments.first)
    generation&.update!(status: "failed", error_message: I18n.t('ai.errors.timeout'))
  end

  def perform(generation_id)
    generation = AiGeneration.find_by(id: generation_id)
    return unless generation && generation.status.in?(%w[queued running])

    generation.update!(status: "running")
    params = generation.request_params

    result = case generation.kind
             when "video"
               ActivityFromVideoService.new(
                 youtube_url: params["youtube_url"],
                 transcript:  params["transcript"],
                 teacher:     generation.teacher,
                 level_hint:  params["level_hint"].presence
               ).call
             when "agent"
               generate_for_agent(generation, params)
             else
               ActivityGenerationService.new(prompt: params["prompt"], teacher: generation.teacher).call
             end

    if result[:success]
      generation.update!(status: "done", activity: result[:activity])
    else
      generation.update!(status: "failed", error_message: result[:error])
    end
  rescue Anthropic::Errors::RateLimitError, Anthropic::Errors::APITimeoutError, Anthropic::Errors::APIConnectionError
    raise # temporários: retry do job
  rescue => e
    Rails.logger.error "AiActivityGenerationJob: #{e.class} - #{e.message}"
    generation&.update!(status: "failed", error_message: I18n.t('ai.errors.generic'))
  end

  private

  # Agente de conteúdo do admin: escolhe o prompt do template para o nível
  # pedido e, se a atividade sugerir um vídeo, busca a URL no YouTube.
  def generate_for_agent(generation, params)
    require Rails.root.join("lib/activity_prompt_templates")

    level    = params["level"]
    existing = Activity.where(teacher: generation.teacher, ai_generated: true, level: level)
    prompt   = ActivityPromptTemplates.pick(level, existing_count: existing.count)

    # Anti-repetição: o agente conhece o catálogo e evita "mais do mesmo"
    existing_titles = existing.order(created_at: :desc).limit(20).pluck(:title)
    if existing_titles.any?
      prompt += "\n\nATENÇÃO — o nível #{level} já tem estas atividades; crie algo claramente " \
                "DIFERENTE de todas, em tema, cenário e personagens:\n" +
                existing_titles.map { |t| "- #{t}" }.join("\n")
    end

    result = ActivityGenerationService.new(prompt: prompt, teacher: generation.teacher).call

    if result[:success] && (query = result[:search_query])
      video_url = YoutubeSearchService.new(query: query).call
      result[:activity].update_column(:video_url, video_url) if video_url
    end

    result
  end
end
