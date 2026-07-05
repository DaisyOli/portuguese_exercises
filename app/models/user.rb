class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  has_many :activities, foreign_key: :teacher_id, dependent: :destroy
  has_many :students, class_name: 'User', foreign_key: :invited_by_id
  has_many :quiz_attempts, dependent: :destroy
  has_many :push_subscriptions, dependent: :destroy
  
  ROLES = %w[teacher student trial].freeze
  LANGUAGES = %w[en pt fr].freeze
  CEFR_LEVELS = %w[A1 A2 B1 B2 C1].freeze
  DEFAULT_LANGUAGE = 'pt'.freeze
  PROFESSIONAL_TYPES = %w[OPCO eCPF].freeze

  scope :teachers, -> { where(role: 'teacher') }
  scope :students, -> { where(role: 'student') }
  scope :trials,   -> { where(role: 'trial') }

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :language, presence: true, inclusion: { in: LANGUAGES }
  validates :name, length: { maximum: 50 }, allow_blank: true
  validates :level, presence: true, inclusion: { in: CEFR_LEVELS }, if: :trial?
  validates :professional_type, inclusion: { in: PROFESSIONAL_TYPES }, allow_blank: true

  before_validation :set_default_language, on: :create
  after_commit :notify_admin_if_teacher_joined

  def admin?
    admin == true
  end

  def teacher?
    role == 'teacher'
  end

  def student?
    role == 'student'
  end

  def trial?
    role == 'trial'
  end

  def student_like?
    student? || trial?
  end

  def trial_expired?
    trial? && (trial_expires_at.nil? || trial_expires_at < Time.current)
  end

  def trial_exhausted?
    trial? && trial_activities_used.to_i >= 3
  end

  DAILY_STUDENT_LIMIT = 3

  def trial_access_active?
    trial? && !trial_expired? && !trial_exhausted?
  end

  def daily_limit_reached?
    return false unless student?
    daily_quiz_date == Date.current && daily_quiz_count.to_i >= DAILY_STUDENT_LIMIT
  end

  def increment_daily_count!
    return unless student?
    if daily_quiz_date == Date.current
      increment!(:daily_quiz_count)
    else
      update!(daily_quiz_count: 1, daily_quiz_date: Date.current)
    end
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
    return [level] if trial?
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

  def notify_admin_if_teacher_joined
    return unless teacher?
    return unless saved_change_to_invitation_accepted_at? && invitation_accepted_at.present?
    AdminMailer.new_teacher_notification(self).deliver_later
  end
end
