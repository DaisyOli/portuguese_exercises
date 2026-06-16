module QuizManagement
  extend ActiveSupport::Concern

  private

  def ensure_quiz_access
    redirect_to activities_path unless current_user.student?
  end

  def load_quiz_attempt
    @quiz_attempt = current_user.quiz_attempts.find_by(
      activity: @activity,
      id: session[:quiz_attempt_id]
    )
  end

  def clear_quiz_session
    session.delete(:quiz_attempt_id)
    session.delete(:last_quiz_score)
  end

  def load_questions
    if params[:skip_cache] == "true"
      @activity.questions.to_a
    else
      Rails.cache.fetch(["activity_questions", @activity.id, @activity.updated_at.to_i], expires_in: 1.hour) do
        @activity.questions.to_a
      end
    end
  end

  def load_completed_exercises
    session[:completed_quizzes] = current_user.quiz_attempts
                                              .select(:activity_id)
                                              .distinct
                                              .pluck(:activity_id)
  end
end 