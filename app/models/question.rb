class Question < ApplicationRecord
  belongs_to :activity

  validates :content, presence: true
  validates :correct_answer, presence: true
  validates :options, presence: true
  validate :correct_answer_in_options
  
  before_validation :ensure_options_is_array

  private

  def correct_answer_in_options
    if correct_answer.present? && options.is_a?(Array) && !options.include?(correct_answer)
      errors.add(:correct_answer, "deve ser uma das opções disponíveis")
    end
  end

  def ensure_options_is_array
    self.options ||= []
    self.options = options.reject(&:blank?) if options.is_a?(Array)
  end
end

