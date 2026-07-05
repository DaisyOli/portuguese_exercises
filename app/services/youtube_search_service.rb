require "net/http"
require "json"

# Integração com YouTube Data API v3.
# Para ativar: criar chave em console.cloud.google.com → YouTube Data API v3
# e rodar: heroku config:set YOUTUBE_API_KEY=...
# Sem a chave, o serviço retorna nil.
class YoutubeSearchService
  API_BASE = "https://www.googleapis.com/youtube/v3/search".freeze

  def initialize(query:)
    @query   = query
    @api_key = ENV["YOUTUBE_API_KEY"]
  end

  # Retorna hash com :youtube_url, :title, :channel_name, :thumbnail_url
  # ou nil se a API não estiver configurada ou não encontrar resultado.
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
      videoCaption:      "closedCaption",
      safeSearch:        "strict",
      maxResults:        1,
      key:               @api_key
    )

    response = Net::HTTP.get_response(uri)
    return nil unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)
    item = data.dig("items", 0)
    return nil unless item

    video_id = item.dig("id", "videoId")
    return nil unless video_id

    snippet = item["snippet"] || {}
    {
      youtube_url:   "https://www.youtube.com/watch?v=#{video_id}",
      title:         snippet["title"].to_s,
      channel_name:  snippet["channelTitle"].to_s,
      thumbnail_url: snippet.dig("thumbnails", "medium", "url").to_s
    }
  rescue => e
    Rails.logger.error "[YoutubeSearch] #{e.class}: #{e.message}"
    nil
  end
end
