require "net/http"
require "json"

# Integração com YouTube Data API v3.
# Código deployado mas INATIVO por decisão da Daisy (junho/2026) — evitar custos da API.
# Para ativar: criar chave em console.cloud.google.com → YouTube Data API v3
# e rodar: heroku config:set YOUTUBE_API_KEY=...
# Sem a chave, o serviço retorna nil e a atividade é salva normalmente sem vídeo.
class YoutubeSearchService
  API_BASE = "https://www.googleapis.com/youtube/v3/search".freeze

  def initialize(query:)
    @query    = query
    @api_key  = ENV["YOUTUBE_API_KEY"]
  end

  def call
    return nil unless @api_key.present?

    uri = URI(API_BASE)
    uri.query = URI.encode_www_form(
      part:              "snippet",
      type:              "video",
      q:                 "#{@query} português brasileiro",
      relevanceLanguage: "pt",
      regionCode:        "BR",
      videoDuration:     "medium",
      safeSearch:        "strict",
      maxResults:        3,
      key:               @api_key
    )

    response = Net::HTTP.get_response(uri)
    return nil unless response.is_a?(Net::HTTPSuccess)

    data     = JSON.parse(response.body)
    video_id = data.dig("items", 0, "id", "videoId")
    video_id ? "https://www.youtube.com/watch?v=#{video_id}" : nil
  rescue => e
    Rails.logger.error "[YoutubeSearch] #{e.class}: #{e.message}"
    nil
  end
end
