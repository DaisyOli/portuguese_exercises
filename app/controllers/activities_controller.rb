class ActivitiesController < ApplicationController
  include QuizManagement
  
  before_action :authenticate_user!
  before_action :set_activity, only: [:show, :edit, :update, :destroy, :resolve_quiz, :submit_quiz, :quiz_results, :clear_statement, :clear_media, :clear_explanation, :clear_attempt_history]
  before_action :authorize_teacher, only: [:new, :create, :edit, :update, :destroy]

  def index
    service_result = ActivitiesIndexService.new(params: params, current_user: current_user).call
    @activities = service_result[:activities]
    @current_level = service_result[:current_level]
    @activities_by_level = service_result[:activities_by_level]
    
    # Para estudantes, carregar dados específicos
    if current_user.student?
      @best_attempts = service_result[:best_attempts]
      load_completed_exercises
    end
  end

  def show
    @questions = load_questions
    
    if current_user.student?
      # Redirecionamento direto para resolver o quiz
      redirect_to resolve_quiz_activity_path(@activity)
    end
  end

  def resolve_quiz
    @questions = load_questions
    
    if params[:show_score] == 'true' && session[:quiz_attempt_id].present?
      @quiz_attempt = QuizAttempt.find_by(id: session[:quiz_attempt_id])
      if @quiz_attempt && @quiz_attempt.activity_id == @activity.id
        @show_score = true
        @score = @quiz_attempt.score
        @total_correct = @quiz_attempt.results["total_correct"]
        @total_questions = @quiz_attempt.results["total_questions"]
      end
    else
      session.delete(:show_score_data) if session[:show_score_data]&.dig("activity_id") == @activity.id
    end
  end

  def submit_quiz
    result = QuizSubmissionService.new(
      activity: @activity,
      user: current_user,
      params: params,
      session: session
    ).call

    if result[:success] && result[:show_score]
      session[:show_score_data] = {
        score: result[:score],
        total_correct: result[:total_correct],
        total_questions: result[:total_questions],
        activity_id: @activity.id
      }
    end

    if result[:success]
      redirect_to result[:redirect_path], notice: result[:notice]
    else
      redirect_to result[:redirect_path], alert: result[:alert]
    end
  end

  def quiz_results
    @quiz_attempt = find_quiz_attempt
    return redirect_to resolve_quiz_activity_path(@activity, locale: I18n.locale),
                        alert: t('messages.answer_quiz_first') if @quiz_attempt.nil?

    @questions    = @activity.questions.index_by(&:id)
    @quiz_results = @quiz_attempt.normalized_results(@questions)
    render 'quiz_results'
  rescue => e
    Rails.logger.error "Erro ao mostrar resultados: #{e.message}\n#{e.backtrace.join("\n")}"
    redirect_to activities_path, alert: "Ocorreu um erro ao exibir os resultados. Tente novamente."
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
      redirect_to activities_path, alert: t('messages.permission_denied') and return
    end
  end

  def update
    if @activity.teacher != current_user
      redirect_to activities_path, alert: t('messages.permission_denied')
      return
    end

    # Guardar valores anteriores para comparar após o update
    had_statement = @activity.statement.present?
    had_media = @activity.media_url.present?
    had_explanation = @activity.explanation_text.present?

    if @activity.update(activity_params)
      # Determinar o tipo de conteúdo que foi adicionado ou atualizado
      ultimo_conteudo = nil
      
      # Verificar qual conteúdo foi adicionado ou atualizado
      if params[:activity][:statement].present?
        ultimo_conteudo = 'statement'
      elsif params[:activity][:media_url].present?
        ultimo_conteudo = 'media'
      elsif params[:activity][:explanation_text].present?
        ultimo_conteudo = 'explanation'
      end
      
      redirect_to activity_path(@activity, ultimo_conteudo: ultimo_conteudo), notice: t('messages.activity_updated')
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
    # Redirecionar para a parte superior da página ou para outro conteúdo
    redirect_to activity_path(@activity, ultima_acao: 'conteudo_excluido'), notice: t('messages.statement_deleted')
  end

  def clear_media
    if @activity.teacher != current_user
      redirect_to activities_path, alert: t('messages.permission_denied') and return
    end

    @activity.update(media_url: nil)
    redirect_to activity_path(@activity, ultima_acao: 'conteudo_excluido'), notice: t('messages.media_deleted')
  end

  def clear_explanation
    if @activity.teacher != current_user
      redirect_to activities_path, alert: t('messages.permission_denied')
      return
    end

    @activity.update(explanation_text: nil)
    # Redirecionar para a parte superior da página ou para outro conteúdo
    redirect_to activity_path(@activity, ultima_acao: 'conteudo_excluido'), notice: t('messages.explanation_deleted')
  end

  def clear_attempt_history
    @activity = Activity.find_by!(slug: params[:slug])
    
    # Manter apenas a tentativa mais recente
    latest_attempt = current_user.quiz_attempts.where(activity_id: @activity.id).order(created_at: :desc).first
    
    # Remover todas as outras tentativas
    current_user.quiz_attempts.where(activity_id: @activity.id).where.not(id: latest_attempt&.id).destroy_all
    
    redirect_to quiz_results_activity_path(@activity), notice: t('messages.attempt_history_cleared')
  end

  def destroy
    @activity.destroy
    redirect_to activities_url, notice: t('messages.activity_deleted')
  end

  private

  def set_activity
    @activity = Activity.find_by!(slug: params[:slug])
  end

  def find_quiz_attempt
    attempt = QuizAttempt.find_by(id: session[:quiz_attempt_id]) if session[:quiz_attempt_id].present?
    attempt ||= current_user&.quiz_attempts&.where(activity_id: @activity.id)&.order(created_at: :desc)&.first
    attempt
  end

  def activity_params
    params.require(:activity).permit(:title, :description, :level, :media_url, :explanation_text, :statement)
  end
  
  def authorize_teacher
    unless current_user&.teacher?
      redirect_to root_path, alert: "Acesso restrito a professores."
    end
  end
end
