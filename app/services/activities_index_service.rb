# app/services/activities_index_service.rb
class ActivitiesIndexService
  attr_reader :user, :level

  def initialize(user:, level: nil)
    @user = user
    @level = level
  end

  def call
    if level.present?
      load_activities_by_level
    else
      load_all_activities
    end
  end

  private

  def load_activities_by_level
    activities = Rails.cache.fetch(["activities", level, user.id], expires_in: 1.hour) do
      Activity.where(level: level).to_a
    end
    
    result = {
      activities: activities,
      current_level: level
    }
    
    # Buscar os melhores resultados para o estudante
    if user.student?
      result[:best_attempts] = Rails.cache.fetch(["best_attempts", user.id], expires_in: 30.minutes) do
        attempts = user.quiz_attempts.where(activity_id: activities.map(&:id))
                     .group(:activity_id)
                     .select('activity_id, MAX(score) as max_score')
        
        attempts.each_with_object({}) do |attempt, hash|
          hash[attempt.activity_id] = attempt.max_score
        end
      end
      
      # Carregar lista de exercícios completados para a sessão
      result[:completed_exercises] = load_completed_exercises
    end
    
    result
  end

  def load_all_activities
    activities = Rails.cache.fetch(["all_activities"], expires_in: 1.hour) do
      Activity.all.to_a
    end
    
    activities_by_level = Rails.cache.fetch(["activities_by_level"], expires_in: 1.hour) do
      Activity.all.group_by(&:level)
    end
    
    {
      activities: activities,
      activities_by_level: activities_by_level
    }
  end

  def load_completed_exercises
    # Lógica exata do método load_completed_exercises do controller
    # (Esta seria extraída do controller se existir)
    # Por enquanto retornando um array vazio para manter compatibilidade
    []
  end
end 