class UnsplashService
  API_URL = "https://api.unsplash.com/search/photos"

  def initialize(query)
    @query = query.to_s.strip
  end

  def call
    return nil if @query.blank? || ENV["UNSPLASH_ACCESS_KEY"].blank?

    uri = URI(API_URL)
    uri.query = URI.encode_www_form(
      query:       @query,
      per_page:    3,
      orientation: "landscape",
      client_id:   ENV["UNSPLASH_ACCESS_KEY"]
    )

    response = Net::HTTP.get_response(uri)
    return nil unless response.is_a?(Net::HTTPSuccess)

    photos = JSON.parse(response.body)["results"]
    return nil if photos.blank?

    photo = photos.sample
    {
      url:              photo.dig("urls", "regular"),
      photographer:     photo.dig("user", "name"),
      photographer_url: "#{photo.dig('user', 'links', 'html')}?utm_source=practicebr&utm_medium=referral"
    }
  rescue StandardError
    nil
  end
end
