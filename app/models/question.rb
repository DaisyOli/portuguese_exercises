class Question < ApplicationRecord
  belongs_to :activity, touch: true

  attr_accessor :options_text

  QUESTION_TYPES = ['multiple_choice', 'fill_in_blank', 'open_ended']

  scope :by_type, ->(type) { where(question_type: type) }

  validates :content, presence: true
  validates :correct_answer, presence: true, unless: -> { open_ended? || fill_in_blank? }
  validates :question_type, presence: true, inclusion: { in: QUESTION_TYPES }
  validates :options, presence: true, if: :multiple_choice?
  validates :weight, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 3 }, allow_nil: false
  validate :correct_answer_in_options, if: :multiple_choice?
  validate :fill_in_blank_answers_valid, if: :fill_in_blank?

  before_validation :ensure_options_is_array
  before_validation :process_options_text

  def multiple_choice?
    question_type == 'multiple_choice'
  end
  
  def fill_in_blank?
    question_type == 'fill_in_blank'
  end

  def open_ended?
    question_type == 'open_ended'
  end

  def all_correct_answers
    arr = correct_answers.presence&.reject(&:blank?)
    arr.present? ? arr : [correct_answer].compact
  end

  def blank_count
    content.to_s.scan('_____').length
  end

  private

  def correct_answer_in_options
    if correct_answer.present? && options.is_a?(Array) && !options.include?(correct_answer)
      errors.add(:correct_answer, "deve ser uma das opções disponíveis")
    end
  end

  def fill_in_blank_answers_valid
    unless content&.include?('_____')
      errors.add(:content, "deve conter pelo menos um espaço em branco (_____)")
      return
    end
    answers = all_correct_answers
    if answers.empty? || answers.any?(&:blank?)
      errors.add(:base, "Todas as lacunas precisam de uma resposta correta")
    elsif answers.length != blank_count
      errors.add(:base, "Número de respostas (#{answers.length}) deve ser igual ao número de lacunas (#{blank_count})")
    end
  end
  
  def ensure_options_is_array
    self.options ||= []
    self.options = options.reject(&:blank?) if options.is_a?(Array)
  end

  def process_options_text
    if options_text.present? && multiple_choice?
      self.options = options_text.split(",").map(&:strip)
    end
  end
end

