class ActivitiesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_activity, only: [:show, :edit, :update, :destroy, :resolve_quiz, :submit_quiz, :quiz_results, :clear_statement, :clear_media, :clear_explanation]

  def index
    if params[:level].present?
      @activities = Activity.where(level: params[:level])
      @current_level = params[:level]
    else
      @activities = Activity.all
      @activities_by_level = Activity.all.group_by(&:level)
    end
    
    # Carregar as melhores tentativas para cada atividade se o usuário for um aluno
    if current_user.student?
      activity_ids = @activities.pluck(:id)
      @best_attempts = {}
      
      # Obter a melhor tentativa para cada atividade
      QuizAttempt.where(user_id: current_user.id, activity_id: activity_ids)
                .group(:activity_id)
                .select('activity_id, MAX(score) as max_score')
                .each do |attempt|
        # Armazenar a melhor pontuação para cada atividade
        @best_attempts[attempt.activity_id] = attempt.max_score
      end
      
      # Obter as tentativas mais recentes para cada atividade
      @recent_attempts = {}
      QuizAttempt.where(user_id: current_user.id, activity_id: activity_ids)
                .group(:activity_id)
                .select('activity_id, MAX(completed_at) as last_attempt')
                .each do |attempt|
        # Usar a data da tentativa mais recente para cada atividade
        @recent_attempts[attempt.activity_id] = attempt.last_attempt
      end
    end
    
    Rails.logger.info "Melhores tentativas: #{@best_attempts.inspect}" if @best_attempts
  end

  def show
    @questions = @activity.questions
    if current_user.role == "student"
      # Verificar se o aluno já tentou esta atividade
      @last_attempt = current_user.quiz_attempts.where(activity_id: @activity.id).order(completed_at: :desc).first
      
      if @last_attempt.present?
        redirect_to quiz_results_activity_path(@activity, attempt_id: @last_attempt.id)
      else
        redirect_to resolve_quiz_activity_path(@activity)
      end
    end
  end

  def resolve_quiz
    @questions = @activity.questions
  end

  def submit_quiz
    @activity = Activity.find(params[:id])
    @questions = @activity.questions
    
    # Processa os parâmetros para extrair as respostas
    answers = params[:answers] || {}
    
    Rails.logger.info "Respostas processadas: #{answers.inspect}"
    
    results = {}
    total_correct = 0
    
    @questions.each do |question|
      given_answer = answers[question.id.to_s]
      correct_answer = question.correct_answer
      
      is_correct = false
      
      # Processa diferentes tipos de questões
      case question.question_type
      when 'multiple_choice'
        is_correct = given_answer.present? && given_answer.to_s.strip == correct_answer.to_s.strip
      when 'fill_in_blank'
        is_correct = given_answer.present? && given_answer.to_s.strip == correct_answer.to_s.strip
      when 'order_sentences'
        # Para questões de ordenação, compara a ordem dada com a ordem correta
        is_correct = given_answer.present? && given_answer.to_s == correct_answer.to_s
      end
      
      total_correct += 1 if is_correct
      
      results[question.id] = {
        question_text: question.content,
        question_type: question.question_type,
        given_answer: given_answer.presence || t('quiz.not_answered'),
        correct_answer: correct_answer,
        is_correct: is_correct
      }
    end
    
    score = ((total_correct.to_f / @questions.count) * 100).round(2)
    
    # Salva a tentativa no banco de dados
    @quiz_attempt = current_user.quiz_attempts.new(
      activity: @activity,
      score: score,
      total_questions: @questions.count,
      correct_answers: total_correct,
      answers_data: results,
      completed_at: Time.current
    )
    
    # Calcula XP ganho
    @quiz_attempt.xp_earned = @quiz_attempt.calculate_xp
    
    if @quiz_attempt.save
      Rails.logger.info "Quiz attempt saved: #{@quiz_attempt.inspect}"
    else
      Rails.logger.error "Failed to save quiz attempt: #{@quiz_attempt.errors.full_messages.join(", ")}"
    end
    
    # Mantenha a sessão temporária para compatibilidade com o código existente
    @quiz_results = {
      activity_id: @activity.id,
      results: results,
      score: score,
      total_correct: total_correct,
      total_questions: @questions.count,
      attempt_id: @quiz_attempt.id
    }
    
    session[:quiz_results] = @quiz_results
    
    respond_to do |format|
      format.html { redirect_to quiz_results_activity_path(@activity), notice: t('messages.quiz_submitted') }
      format.turbo_stream { redirect_to quiz_results_activity_path(@activity), notice: t('messages.quiz_submitted') }
    end
  rescue => e
    Rails.logger.error "Erro ao processar quiz: #{e.message}"
    redirect_to resolve_quiz_activity_path(@activity), alert: t('messages.quiz_error')
  end

  def quiz_results
    @activity = Activity.find(params[:id])
    
    # Tenta obter do banco de dados, depois da sessão como fallback
    if params[:attempt_id].present?
      @quiz_attempt = QuizAttempt.find_by(id: params[:attempt_id])
      if @quiz_attempt
        @quiz_results = {
          activity_id: @activity.id,
          results: @quiz_attempt.answers_data,
          score: @quiz_attempt.score,
          total_correct: @quiz_attempt.correct_answers,
          total_questions: @quiz_attempt.total_questions,
          attempt_id: @quiz_attempt.id,
          xp_earned: @quiz_attempt.xp_earned,
          completed_at: @quiz_attempt.completed_at
        }
      end
    elsif session[:quiz_results].present? && session[:quiz_results]["activity_id"] == @activity.id
      @quiz_results = session[:quiz_results]
      
      if @quiz_results["attempt_id"].present?
        @quiz_attempt = QuizAttempt.find_by(id: @quiz_results["attempt_id"])
      end
    else
      # Tenta encontrar a tentativa mais recente
      @quiz_attempt = current_user.quiz_attempts.where(activity_id: @activity.id).order(completed_at: :desc).first
      
      if @quiz_attempt
        @quiz_results = {
          activity_id: @activity.id,
          results: @quiz_attempt.answers_data,
          score: @quiz_attempt.score,
          total_correct: @quiz_attempt.correct_answers,
          total_questions: @quiz_attempt.total_questions,
          attempt_id: @quiz_attempt.id,
          xp_earned: @quiz_attempt.xp_earned,
          completed_at: @quiz_attempt.completed_at
        }
      end
    end
    
    if @quiz_results.nil?
      redirect_to resolve_quiz_activity_path(@activity), alert: t('messages.answer_quiz_first')
      return
    end
    
    # Obter todas as tentativas para exibir o histórico
    @all_attempts = current_user.quiz_attempts.where(activity_id: @activity.id).order(completed_at: :desc)
    
    render 'quiz_results'
  end

  def new
    @activity = Activity.new
  end

  def create
    @activity = Activity.new(activity_params)
    @activity.teacher = current_user

    if @activity.save
      redirect_to activity_path(@activity), notice: t('messages.activity_created')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    unless @activity.teacher == current_user
      redirect_to activities_path, alert: t('messages.permission_denied')
    end
  end

  def update
    if @activity.teacher != current_user
      redirect_to activities_path, alert: t('messages.permission_denied')
      return
    end

    if @activity.update(activity_params)
      redirect_to @activity, notice: t('messages.activity_updated')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def clear_statement
    if @activity.teacher != current_user
      redirect_to activities_path, alert: t('messages.permission_denied')
      return
    end

    @activity.update(statement: nil)
    redirect_to @activity, notice: t('messages.statement_deleted')
  end

  def clear_media
    if @activity.teacher != current_user
      redirect_to activities_path, alert: t('messages.permission_denied')
      return
    end

    @activity.update(media_url: nil)
    redirect_to @activity, notice: t('messages.media_deleted')
  end

  def clear_explanation
    if @activity.teacher != current_user
      redirect_to activities_path, alert: t('messages.permission_denied')
      return
    end

    @activity.update(explanation_text: nil)
    redirect_to @activity, notice: t('messages.explanation_deleted')
  end

  def destroy
    @activity.destroy
    redirect_to activities_url, notice: t('messages.activity_deleted')
  end

  private

  def set_activity
    @activity = Activity.find(params[:id])
  end

  def activity_params
    params.require(:activity).permit(:title, :description, :level, :media_url, :explanation_text, :statement)
  end
end
