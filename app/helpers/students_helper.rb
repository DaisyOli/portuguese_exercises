module StudentsHelper
  # 🇧🇷 Sistema de Streaks Brasileiro - Helpers Seguros
  
  BRAZILIAN_STREAK_MILESTONES = [
    { days: 2,   icon: '🥖', name: 'Pão Francês',      phrase: 'Voltou no dia seguinte!',     class: 'pao-frances' },
    { days: 3,   icon: '☕', name: 'Cafezinho',        phrase: 'Terceiro dia consecutivo!',   class: 'cafezinho' },
    { days: 5,   icon: '🧀', name: 'Pão de Queijo',   phrase: 'Uma semana de trabalho!',     class: 'pao-queijo' },
    { days: 7,   icon: '🥥', name: 'Água de Coco',    phrase: 'Uma semana completa!',        class: 'agua-coco' },
    { days: 10,  icon: '🍯', name: 'Mel',             phrase: 'Doçura da persistência!',     class: 'mel' },
    { days: 14,  icon: '🥞', name: 'Tapioca',         phrase: 'Duas semanas firme!',         class: 'tapioca' },
    { days: 21,  icon: '🍖', name: 'Churrasco',       phrase: '21 dias = Hábito formado!',   class: 'churrasco' },
    { days: 30,  icon: '🐟', name: 'Moqueca',         phrase: 'Um mês de dedicação!',        class: 'moqueca' },
    { days: 45,  icon: '🍚', name: 'Feijoada',        phrase: 'Quase 7 semanas!',            class: 'feijoada' },
    { days: 60,  icon: '🎭', name: 'Samba',           phrase: 'Dois meses no ritmo!',        class: 'samba' },
    { days: 90,  icon: '🧊', name: 'Açaí',            phrase: 'Um trimestre forte!',         class: 'acai' },
    { days: 120, icon: '🌽', name: 'Pamonha',         phrase: '4 meses = São João!',         class: 'pamonha' },
    { days: 150, icon: '🥮', name: 'Brigadeiro',      phrase: '5 meses de doçura!',          class: 'brigadeiro' },
    { days: 180, icon: '🏖️', name: 'Caipirinha',     phrase: 'Meio ano de praia!',          class: 'caipirinha' },
    { days: 270, icon: '🎪', name: 'Carnaval',        phrase: '9 meses = Carnaval!',         class: 'carnaval' },
    { days: 365, icon: '🇧🇷', name: 'Brasileiro Raiz', phrase: '1 ano = Verdadeiro Brasileiro!', class: 'brasileiro-raiz' }
  ].freeze

  def get_current_badge(streak_days)
    # Busca o maior marco alcançado
    achieved_milestones = BRAZILIAN_STREAK_MILESTONES.select { |m| streak_days >= m[:days] }
    
    if achieved_milestones.any?
      achieved_milestones.last
    else
      # Badge padrão para quem ainda não alcançou nenhum marco
      { days: 0, icon: '🔥', name: 'Iniciante', phrase: 'Comece sua jornada!', class: 'iniciante' }
    end
  end

  def get_next_badge(streak_days)
    # Busca o próximo marco a ser alcançado
    BRAZILIAN_STREAK_MILESTONES.find { |m| streak_days < m[:days] }
  end

  def get_all_achieved_badges(streak_days)
    # Retorna todos os badges já conquistados
    BRAZILIAN_STREAK_MILESTONES.select { |m| streak_days >= m[:days] }
  end

  def get_days_to_next_badge(streak_days)
    next_badge = get_next_badge(streak_days)
    return nil unless next_badge
    
    next_badge[:days] - streak_days
  end

  def get_motivational_message(streak_days)
    case streak_days
    when 0..1   then "Comece hoje sua jornada brasileira! 🇧🇷"
    when 2..6   then "Você está criando um hábito incrível! 💪"
    when 7..20  then "O hábito está se formando! Continue! 🚀"
    when 21..59 then "Hábito formado! Agora é manter o ritmo! 🎯"
    when 60..89 then "Você é dedicado! Que exemplo! 🏆"
    else 
      if streak_days >= 90
        "Você é uma lenda! Inspiração total! 🌟"
      else
        "Continue sua jornada brasileira!"
      end
    end
  end

  def get_streak_progress_percentage(streak_days)
    next_badge = get_next_badge(streak_days)
    return 100 unless next_badge # Se já alcançou todos os marcos
    
    current_badge = get_current_badge(streak_days)
    current_milestone = current_badge[:days]
    next_milestone = next_badge[:days]
    
    # Calcula progresso entre marcos
    if current_milestone == 0
      progress = (streak_days.to_f / next_milestone * 100).round
    else
      progress_range = next_milestone - current_milestone
      current_progress = streak_days - current_milestone
      progress = ((current_progress.to_f / progress_range) * 100).round
    end
    
    [progress, 0].max # Nunca negativo
  end

  def is_recent_achievement?(streak_days)
    # Verifica se acabou de conquistar um badge (útil para animações)
    current_badge = get_current_badge(streak_days)
    current_badge[:days] == streak_days
  end
end
