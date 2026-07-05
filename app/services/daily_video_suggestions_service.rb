require "anthropic"
require "json"

# Gera 3 sugestões de vídeo por dia para cada professor.
# Usa Claude para sugerir temas + YoutubeSearchService para encontrar o vídeo real.
# Invocado pelo rake task video_suggestions:generate (Heroku Scheduler, diariamente).
class DailyVideoSuggestionsService
  COUNT = 3

  def initialize(teacher:)
    @teacher = teacher
  end

  def call
    # Não gerar se já existem sugestões pendentes de hoje
    existing = VideoSuggestion.for_teacher(@teacher).today.pending.count
    return { skipped: true, reason: "already_has_suggestions" } if existing >= COUNT

    topics = generate_topics
    return { success: false, error: "Claude não retornou tópicos" } if topics.blank?

    created = topics.take(COUNT - existing).map { |t| build_suggestion(t) }.compact

    { success: true, created: created.size }
  rescue => e
    Rails.logger.error "[DailyVideoSuggestions] #{e.class}: #{e.message}"
    { success: false, error: e.message }
  end

  private

  def generate_topics
    ActiveRecord::Base.connection_pool.release_connection

    client = Anthropic::Client.new
    response = client.messages(
      model:      "claude-opus-4-8",
      max_tokens: 800,
      messages: [{
        role:    "user",
        content: prompt
      }]
    )

    raw = response.dig("content", 0, "text").to_s.strip
    raw = raw.gsub(/\A```(?:json)?\n?/, '').gsub(/\n?```\z/, '')
    JSON.parse(raw)
  rescue JSON::ParserError => e
    Rails.logger.error "[DailyVideoSuggestions] JSON parse error: #{e.message}"
    nil
  end

  def build_suggestion(topic)
    video = YoutubeSearchService.new(query: topic["search_query"]).call

    VideoSuggestion.create!(
      teacher:       @teacher,
      topic:         topic["topic"],
      level_hint:    topic["level"],
      search_query:  topic["search_query"].to_s,
      thumbnail_url: video&.dig(:thumbnail_url).to_s,
      youtube_url:   video&.dig(:youtube_url).to_s,
      title:         video&.dig(:title).to_s,
      channel_name:  video&.dig(:channel_name).to_s,
      status:        'pending'
    )
  rescue => e
    Rails.logger.error "[DailyVideoSuggestions] Failed to create suggestion: #{e.message}"
    nil
  end

  def prompt
    <<~PROMPT
      Você é um curador de conteúdo para a plataforma Practice-BR, que ensina português brasileiro para adultos estrangeiros.

      Gere #{COUNT} sugestões de tópicos de vídeo para atividades de português, variando os níveis CEFR e os temas.
      Priorize vídeos autênticos brasileiros: podcasts, entrevistas, vlogs, noticiários, culinária, cultura.

      Responda SOMENTE com um array JSON — sem texto antes ou depois:
      [
        {
          "topic": "descrição curta do tema em português (ex: 'Receita de feijoada com chef brasileiro')",
          "level": "B1",
          "search_query": "termo de busca no YouTube em português (ex: 'feijoada receita tradicional chef brasileiro')"
        }
      ]

      Regras:
      - Varie os níveis: use pelo menos um A2/B1, um B1/B2, um B2/C1
      - Temas adultos e contemporâneos: gastronomia, trabalho, viagem, cultura, tecnologia, esporte
      - Search query deve ser específico e em português para encontrar vídeos brasileiros reais
      - NÃO repita temas de dias anteriores (seja criativo)
    PROMPT
  end
end
