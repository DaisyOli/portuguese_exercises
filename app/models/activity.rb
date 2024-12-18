class Activity < ApplicationRecord
  belongs_to :user

  validates :title, presence: true
  validates :description, presence: true
  validates :content_type, inclusion: { in: %w[video texto audio], message: "must be 'video', 'texto' or 'audio'" }
  validate :validate_content_url
  
  private

  def validate_content_url
    if (content_type == "video" || content_type == "audio") && content_url.present?
      uri = URI.parse(content_url)
      errors.add(:content_url, "must be a valid URL") unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
    end
  rescue URI::InvalidURIError
    errors.add(:content_url, "must be a valid URL")
  end
end
