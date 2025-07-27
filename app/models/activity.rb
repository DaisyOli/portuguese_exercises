class Activity < ApplicationRecord
  belongs_to :teacher, class_name: 'User'
  has_many :questions, dependent: :destroy
  has_many :quiz_attempts, dependent: :destroy
  has_many :suggestions, dependent: :destroy

  validates :title, presence: true
  validates :description, presence: true
  validates :level, presence: true
  validates :slug, presence: true, uniqueness: true
  
  before_validation :generate_slug, if: :should_generate_slug?
  after_commit :clear_cache
  
  enum level: {
    A1: 'A1',
    A2: 'A2',
    B1: 'B1',
    B2: 'B2',
    C1: 'C1'
  }

  def level_color_class
    case level
    when 'A1'
      'bg-info'        # Azul claro
    when 'A2'
      'bg-primary'     # Azul
    when 'B1'
      'bg-success'     # Verde
    when 'B2'
      'bg-warning'     # Amarelo
    when 'C1'
      'bg-danger'      # Vermelho
    else
      'bg-secondary'   # Cinza (caso padrão)
    end
  end

  def to_param
    slug
  end
  
  private
  
  def generate_slug
    return unless title.present?
    
    # Criar slug base a partir do título
    base_slug = title.downcase
                    .gsub(/[àáâãäå]/, 'a')
                    .gsub(/[èéêë]/, 'e')
                    .gsub(/[ìíîï]/, 'i')
                    .gsub(/[òóôõö]/, 'o')
                    .gsub(/[ùúûü]/, 'u')
                    .gsub(/[ç]/, 'c')
                    .gsub(/[ñ]/, 'n')
                    .gsub(/[^a-z0-9\s-]/, '') # Remove caracteres especiais
                    .gsub(/\s+/, '-')         # Substitui espaços por hífens
                    .gsub(/-+/, '-')          # Remove hífens duplicados
                    .strip
                    .gsub(/^-|-$/, '')        # Remove hífens do início/fim
    
    # Garantir unicidade
    unique_slug = base_slug
    counter = 1
    
    while Activity.where(slug: unique_slug).where.not(id: self.id).exists?
      unique_slug = "#{base_slug}-#{counter}"
      counter += 1
    end
    
    self.slug = unique_slug
  end
  
  def should_generate_slug?
    title_changed? || slug.blank?
  end
  
  def clear_cache
    Rails.cache.delete_matched("activities*")
    Rails.cache.delete_matched("activity_questions/#{id}*")
    Rails.cache.delete_matched("activities_by_level*")
  end
end
