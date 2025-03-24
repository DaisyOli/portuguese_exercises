class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  has_many :activities, dependent: :destroy
  has_many :quiz_attempts, dependent: :destroy
  
  ROLES = %w[teacher student].freeze
  LANGUAGES = %w[en pt fr].freeze
  DEFAULT_LANGUAGE = 'pt'.freeze

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :language, presence: true, inclusion: { in: LANGUAGES }

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

  private

  def set_default_language
    self.language ||= DEFAULT_LANGUAGE
  end
end
