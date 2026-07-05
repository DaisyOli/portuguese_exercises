require "net/http"
require "cgi"

class YoutubeTranscriptService
  class InvalidUrl < StandardError; end

  def initialize(url)
    @url      = url.to_s.strip
    @video_id = extract_video_id(@url)
  end

  def video_id
    @video_id
  end

  def valid?
    @video_id.present?
  end

  private

  def extract_video_id(url)
    patterns = [
      /[?&]v=([a-zA-Z0-9_-]{11})/,
      /youtu\.be\/([a-zA-Z0-9_-]{11})/,
      /youtube\.com\/embed\/([a-zA-Z0-9_-]{11})/,
      /youtube\.com\/shorts\/([a-zA-Z0-9_-]{11})/
    ]
    patterns.each do |pat|
      m = url.match(pat)
      return m[1] if m
    end
    url.strip if url.strip.match?(/\A[a-zA-Z0-9_-]{11}\z/)
  end
end
