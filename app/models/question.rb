class Question < ApplicationRecord
  belongs_to :activity
  
  # Atributos virtuais
  attr_accessor :options_text, :sentences_content
  
  # Define os tipos de questões disponíveis
  QUESTION_TYPES = ['multiple_choice', 'fill_in_blank', 'order_sentences']
  
  validates :content, presence: true, unless: :order_sentences?
  validates :correct_answer, presence: true
  validates :question_type, presence: true, inclusion: { in: QUESTION_TYPES }
  
  # Validações específicas para cada tipo de questão
  validates :options, presence: true, if: :multiple_choice?
  validate :correct_answer_in_options, if: :multiple_choice?
  validate :content_has_blank, if: :fill_in_blank?
  
  before_validation :ensure_options_is_array
  before_validation :process_options_text
  before_validation :process_order_sentences, if: :order_sentences?
  
  # Callback para limpar o cache
  after_commit :clear_cache
  
  # Métodos auxiliares para verificar o tipo de questão
  def multiple_choice?
    question_type == 'multiple_choice'
  end
  
  def fill_in_blank?
    question_type == 'fill_in_blank'
  end
  
  def order_sentences?
    question_type == 'order_sentences'
  end

  private
  
  def clear_cache
    Rails.cache.delete_matched("activity_questions/#{activity_id}*")
  end

  def correct_answer_in_options
    if correct_answer.present? && options.is_a?(Array) && !options.include?(correct_answer)
      errors.add(:correct_answer, "deve ser uma das opções disponíveis")
    end
  end

  def content_has_blank
    unless content&.include?('_____')
      errors.add(:content, "deve conter pelo menos um espaço em branco (_____)")
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

  def process_order_sentences
    if order_sentences?
      if sentences_content.present?
        sentences = sentences_content.split("\n").map(&:strip).reject(&:blank?)
        self.content = "" # Define o content como vazio para questões de ordenar frases
        self.options = sentences.shuffle
        self.correct_answer = sentences.join("|")
      else
        errors.add(:sentences_content, "não pode ficar em branco")
      end
    end
  end
end

