class Question < ApplicationRecord
  belongs_to :activity
  
  # Atributos virtuais
  attr_accessor :options_text, :sentences_content
  
  # Define os tipos de questões disponíveis
  QUESTION_TYPES = ['multiple_choice', 'fill_in_blank']
  
  # Validação de conteúdo só para tipos que não são order_sentences
  validates :content, presence: true
  
  # Validação de resposta correta (exceto quando processamos sentences)
  validates :correct_answer, presence: true
  
  # Validação de tipo de questão
  validates :question_type, presence: true, inclusion: { in: QUESTION_TYPES }
  
  # Validações específicas para cada tipo de questão
  validates :options, presence: true, if: :multiple_choice?
  validate :correct_answer_in_options, if: :multiple_choice?
  validate :content_has_blank, if: :fill_in_blank?
  
  before_validation :ensure_options_is_array
  before_validation :process_options_text
  
  # Callback para limpar o cache
  after_commit :clear_cache
  
  # Métodos auxiliares para verificar o tipo de questão
  def multiple_choice?
    question_type == 'multiple_choice'
  end
  
  def fill_in_blank?
    question_type == 'fill_in_blank'
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
end

