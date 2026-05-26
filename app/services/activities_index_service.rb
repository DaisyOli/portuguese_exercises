# app/services/activities_index_service.rb
class ActivitiesIndexService
  attr_reader :user, :level

  def initialize(params:, current_user:)
    @params = params
    @current_user = current_user
  end

  def call
    activities = fetch_activities
    activity_ids = activities.pluck(:id)
    {
      activities:          activities,
      current_level:       @params[:level],
      activities_by_level: fetch_activities_by_level,
      best_attempts:       fetch_best_attempts(activity_ids),
      attempt_stats:       fetch_attempt_stats(activity_ids)
    }
  end

  private

  def fetch_activities
    activities = Activity.all

    # Aplicar filtros
    activities = activities.where(level: @params[:level]) if @params[:level].present?
    activities = activities.where("title ILIKE ?", "%#{@params[:search]}%") if @params[:search].present?

    # Aplicar ordenação
    apply_sorting(activities).page(@params[:page]).per(9)
  end

  def apply_sorting(activities)
    case @params[:sort]
    when 'antigos'
      activities.order(created_at: :asc)
    when 'titulo'
      activities.order(title: :asc)
    when 'tentativas'
      activities.left_joins(:quiz_attempts)
                .group('activities.id')
                .order('COUNT(quiz_attempts.id) DESC')
    else # 'recentes' ou padrão
      activities.order(created_at: :desc)
    end
  end

  def fetch_activities_by_level
    Rails.cache.fetch(["activities_by_level"], expires_in: 1.hour) do
      Activity.all.group_by(&:level)
    end
  end

  def fetch_attempt_stats(activity_ids)
    return { counts: {}, unique_users: {} } if activity_ids.empty?

    counts = QuizAttempt.where(activity_id: activity_ids)
                        .group(:activity_id)
                        .count

    unique_users = QuizAttempt.where(activity_id: activity_ids)
                              .where.not(user_id: nil)
                              .group(:activity_id)
                              .distinct
                              .count(:user_id)

    { counts: counts, unique_users: unique_users }
  end

  def fetch_best_attempts(activity_ids)
    return {} unless @current_user.student?

    Rails.cache.fetch(["best_attempts", @current_user.id], expires_in: 30.minutes) do
      attempts = @current_user.quiz_attempts
                            .where(activity_id: activity_ids)
                            .group(:activity_id)
                            .select('activity_id, MAX(score) as max_score')
      
      attempts.each_with_object({}) do |attempt, hash|
        hash[attempt.activity_id] = attempt.max_score
      end
    end
  end
end 