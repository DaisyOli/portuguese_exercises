class Activity < ApplicationRecord
  belongs_to :user
  has_many :questions, dependent: :destroy

  # Constantes
  LEVELS = %w[A1 A2 B1 B2 C1 C2].freeze
  CONTENT_TYPES = %w[video texto audio].freeze

  # Validações
  validates :title, presence: true
  validates :description, presence: true
  validates :content_type, inclusion: { in: CONTENT_TYPES, message: "must be 'video', 'texto', or 'audio'" }
  validates :level, inclusion: { in: LEVELS, message: "must be one of: #{LEVELS.join(', ')}" }
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
