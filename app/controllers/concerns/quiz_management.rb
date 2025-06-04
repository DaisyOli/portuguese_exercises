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

  def log_quiz_debug_info(questions)
    Rails.logger.debug "=== DIAGNÓSTICO DE EXIBIÇÃO DE QUESTÕES ==="
    Rails.logger.debug "Atividade ID: #{@activity.id}, Título: #{@activity.title}"
    Rails.logger.debug "Total de questões carregadas: #{questions.count}"
    Rails.logger.debug "Cache utilizado: #{params[:skip_cache] != 'true'}"
    questions.each_with_index do |q, i|
      Rails.logger.debug "Questão #{i+1}: ID=#{q.id}, Tipo=#{q.question_type}, Conteúdo=#{q.content.truncate(50) if q.content.present?}"
    end
    Rails.logger.debug "=========================================="
  end

  def load_completed_exercises
    # Inicializar array de exercícios concluídos na sessão se não existir
    session[:completed_quizzes] ||= []
    
    # Buscar tentativas do usuário para as atividades do nível atual
    if current_user && defined?(@activities) && @activities.any?
      completed_activity_ids = current_user.quiz_attempts
                                          .where(activity_id: @activities.map(&:id))
                                          .pluck(:activity_id)
                                          .uniq
      
      # Mesclar com a sessão
      session[:completed_quizzes] = (session[:completed_quizzes] + completed_activity_ids).uniq
    end
    
    session[:completed_quizzes]
  end
end 