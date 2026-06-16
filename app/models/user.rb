class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  has_many :activities, foreign_key: :teacher_id, dependent: :destroy
  has_many :students, class_name: 'User', foreign_key: :invited_by_id
  has_many :quiz_attempts, dependent: :destroy
  
  ROLES = %w[teacher student].freeze
  LANGUAGES = %w[en pt fr].freeze
  CEFR_LEVELS = %w[A1 A2 B1 B2 C1].freeze
  DEFAULT_LANGUAGE = 'pt'.freeze

  scope :teachers, -> { where(role: 'teacher') }
  scope :students, -> { where(role: 'student') }

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :language, presence: true, inclusion: { in: LANGUAGES }
  validates :name, length: { maximum: 50 }, allow_blank: true

  before_validation :set_default_language, on: :create

  def teacher?
    role == 'teacher'
  end

  def student?
    role == 'student'
  end

  def language_name
    language_name_for(language)
  end

  def language_name_for(lang_code)
    case lang_code.to_s
    when 'pt' then 'Português'
    when 'en' then 'English'
    when 'fr' then 'Français'
    else 'English'
    end
  end

  def display_name
    name.present? ? name : email.split('@').first.capitalize
  end

  def greeting_name
    name.presence
  end

  def accessible_levels
    return [] if level.blank?
    idx = CEFR_LEVELS.index(level)
    idx ? CEFR_LEVELS[0..idx] : []
  end

  def level_assigned?
    level.present?
  end

  private

  def set_default_language
    self.language ||= DEFAULT_LANGUAGE
  end
end
