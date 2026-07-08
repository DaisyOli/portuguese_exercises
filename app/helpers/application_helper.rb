module ApplicationHelper
  CEFR_COLORS = {
    'A1' => { bg: '#E8F5EE', text: '#0F3826', border: '#2A9B6F', bar: '#2A9B6F', label: 'Iniciante' },
    'A2' => { bg: '#EBF2FC', text: '#1A4A8A', border: '#2563EB', bar: '#2563EB', label: 'Básico' },
    'B1' => { bg: '#F5F3FF', text: '#4C1D95', border: '#7C3AED', bar: '#7C3AED', label: 'Intermediário' },
    'B2' => { bg: '#FFF7ED', text: '#7C2D12', border: '#EA580C', bar: '#EA580C', label: 'Avançado' },
    'C1' => { bg: '#F3F4F6', text: '#1C1917', border: '#374151', bar: '#374151', label: 'Proficiente' },
  }.freeze

  PROFESSIONAL_COLORS = {
    'OPCO' => { bg: '#EFF6FF', text: '#1D4ED8', border: '#BFDBFE' },
    'eCPF' => { bg: '#F5F3FF', text: '#7C3AED', border: '#DDD6FE' },
  }.freeze

  def cefr_colors(level)
    CEFR_COLORS[level] || CEFR_COLORS['A1']
  end

  def format_training_duration(total_minutes)
    return "—" if total_minutes.nil? || total_minutes == 0
    h = total_minutes / 60
    m = total_minutes % 60
    h > 0 ? "#{h}h #{m.to_s.rjust(2, '0')}min" : "#{m}min"
  end

  def professional_badge_html(user)
    return '' if user.professional_type.blank?
    c = PROFESSIONAL_COLORS[user.professional_type] || { bg: '#F3F4F6', text: '#374151', border: '#D1D5DB' }
    content_tag(:span, user.professional_type,
      style: "font-family:'DM Mono',monospace; font-size:0.68rem; font-weight:700; letter-spacing:0.04em; " \
             "background:#{c[:bg]}; color:#{c[:text]}; border:1.5px solid #{c[:border]}; " \
             "padding:2px 8px; border-radius:20px; flex-shrink:0;")
  end

  def activity_competencies(activity, open_ended_ids = Set.new, av_activity_ids = Set.new)
    comps = []
    has_av = activity.video_url.present? || av_activity_ids.include?(activity.id)
    comps << (has_av ? :co : :ce)
    comps << :ee if open_ended_ids.include?(activity.id)
    comps
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
    elsif activity.unsplash_cover_url.present?
      { type: :image, url: activity.unsplash_cover_url, credit: activity.unsplash_cover_credit }
    else
      { type: :gradient, icon: 'bi-journal-text' }
    end
  end
end
