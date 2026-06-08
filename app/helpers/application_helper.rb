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

  def activity_media_badge(activity)
    if activity.image_file.attached? || (activity.media_url.present? && !activity.media_url.match?(/youtube\.com|youtu\.be/))
      { icon: 'bi-image', label: 'Imagem' }
    elsif activity.video_url.present? || activity.video_file.attached?
      { icon: 'bi-play-circle', label: 'Vídeo' }
    elsif activity.audio_file.attached?
      { icon: 'bi-music-note-beamed', label: 'Áudio' }
    else
      { icon: 'bi-journal-text', label: 'Texto' }
    end
  end

  def activity_cover(activity)
    if activity.image_file.attached?
      { type: :image, url: rails_blob_path(activity.image_file, disposition: 'inline') }
    elsif activity.media_url.present? && !activity.media_url.match?(/youtube\.com|youtu\.be/)
      { type: :image, url: activity.media_url }
    elsif activity.video_url.present?
      yt = activity.video_url.match(/(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/)
      yt ? { type: :image, url: "https://img.youtube.com/vi/#{yt[1]}/hqdefault.jpg" } : { type: :gradient, icon: 'bi-play-circle' }
    elsif activity.video_file.attached?
      { type: :gradient, icon: 'bi-play-circle' }
    elsif activity.audio_file.attached?
      { type: :gradient, icon: 'bi-music-note-beamed' }
    else
      { type: :gradient, icon: 'bi-journal-text' }
    end
  end
end
