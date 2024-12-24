class Question < ApplicationRecord
  belongs_to :activity

  validates :content, presence: true
  validates :correct_answer, presence: true
  validate :correct_answer_in_options
  after_initialize :set_default_options
  
  private

  def correct_answer_in_options
    if correct_answer.present? && options.is_a?(Array) && !options.include?(correct_answer)
      errors.add(:correct_answer, "must be one of the answer options")
    end
  end

  def set_default_options
    self.options ||= []
  end
end

