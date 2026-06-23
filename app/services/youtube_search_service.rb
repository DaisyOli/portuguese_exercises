require "net/http"
require "json"

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
