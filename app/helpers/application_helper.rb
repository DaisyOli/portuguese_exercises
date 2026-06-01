module ApplicationHelper
  CEFR_COLORS = {
    'A1' => { bg: '#E8F5EE', text: '#0F3826', border: '#2A9B6F', bar: '#2A9B6F', label: 'Iniciante' },
    'A2' => { bg: '#EBF2FC', text: '#1A4A8A', border: '#2563EB', bar: '#2563EB', label: 'Básico' },
    'B1' => { bg: '#F5F3FF', text: '#4C1D95', border: '#7C3AED', bar: '#7C3AED', label: 'Intermediário' },
    'B2' => { bg: '#FFF7ED', text: '#7C2D12', border: '#EA580C', bar: '#EA580C', label: 'Avançado' },
    'C1' => { bg: '#F3F4F6', text: '#1C1917', border: '#374151', bar: '#374151', label: 'Proficiente' },
  }.freeze

  def cefr_colors(level)
    CEFR_COLORS[level] || CEFR_COLORS['A1']
  end
end
