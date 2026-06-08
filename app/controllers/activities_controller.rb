class ActivitiesController < ApplicationController
  include QuizManagement
  
  before_action :authenticate_user!
  before_action :set_activity, only: [:show, :edit, :update, :destroy, :resolve_quiz, :submit_quiz, :quiz_results, :clear_statement, :clear_media, :clear_video, :clear_explanation, :clear_audio, :clear_image_file, :clear_video_file, :clear_attempt_history, :review_draft, :publish_draft]
  before_action :preload_exercise_associations, only: [:show]
  before_action :authorize_teacher, only: [:new, :create, :edit, :update, :destroy, :generate_with_ai, :review_draft, :publish_draft]

  def index
    service_result = ActivitiesIndexService.new(params: params, current_user: current_user).call
    @activities        = service_result[:activities]
    @current_level     = service_result[:current_level]
    @activities_by_level = service_result[:activities_by_level]
    @attempt_stats     = service_result[:attempt_stats]

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
    if current_user.student? && @activity.draft?
      redirect_to student_dashboard_path, alert: "Esta atividade ainda não está disponível." and return
    end
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

  def generate_with_ai
    if request.get?
      @activity = Activity.new
      return
    end

    prompt = params[:ai_prompt].to_s.strip
    if prompt.blank?
      flash.now[:alert] = "Por favor, descreva a atividade que deseja gerar."
      @activity = Activity.new
      return render :generate_with_ai, status: :unprocessable_entity
    end

    result = ActivityGenerationService.new(prompt: prompt, teacher: current_user).call

    if result[:success]
      redirect_to review_draft_activity_path(result[:activity]),
                  notice: "Atividade gerada! Revise e publique quando estiver pronto."
    else
      flash.now[:alert] = result[:error]
      @activity = Activity.new
      render :generate_with_ai, status: :unprocessable_entity
    end
  end

  def review_draft
    unless @activity.teacher == current_user
      redirect_to activities_path, alert: t('messages.permission_denied') and return
    end
    @questions           = @activity.questions.to_a
    @sentence_orderings  = @activity.sentence_orderings.to_a
    @paragraph_orderings = @activity.paragraph_orderings.includes(:paragraph_sentences).to_a
    @column_matchings    = @activity.column_matchings.includes(:matching_pairs).to_a
  end

  def publish_draft
    unless @activity.teacher == current_user
      redirect_to activities_path, alert: t('messages.permission_denied') and return
    end

    if @activity.update(draft: false)
      redirect_to activity_path(@activity), notice: "Atividade publicada com sucesso!"
    else
      redirect_to review_draft_activity_path(@activity), alert: "Erro ao publicar atividade."
    end
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
      elsif params[:activity][:video_url].present?
        ultimo_conteudo = 'video'
      elsif params[:activity][:explanation_text].present?
        ultimo_conteudo = 'explanation'
      elsif params[:activity][:audio_file].present?
        ultimo_conteudo = 'audio'
      elsif params[:activity][:image_file].present?
        ultimo_conteudo = 'image_file'
      elsif params[:activity][:video_file].present?
        ultimo_conteudo = 'video_file'
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

  def clear_video
    if @activity.teacher != current_user
      redirect_to activities_path, alert: t('messages.permission_denied') and return
    end

    @activity.update(video_url: nil)
    redirect_to activity_path(@activity, ultima_acao: 'conteudo_excluido'), notice: t('messages.video_deleted')
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

  def clear_audio
    redirect_to activities_path, alert: t('messages.permission_denied') and return unless @activity.teacher == current_user
    @activity.audio_file.purge
    redirect_to activity_path(@activity, ultima_acao: 'conteudo_excluido'), notice: t('messages.audio_deleted')
  end

  def clear_image_file
    redirect_to activities_path, alert: t('messages.permission_denied') and return unless @activity.teacher == current_user
    @activity.image_file.purge
    redirect_to activity_path(@activity, ultima_acao: 'conteudo_excluido'), notice: t('messages.image_file_deleted')
  end

  def clear_video_file
    redirect_to activities_path, alert: t('messages.permission_denied') and return unless @activity.teacher == current_user
    @activity.video_file.purge
    redirect_to activity_path(@activity, ultima_acao: 'conteudo_excluido'), notice: t('messages.video_file_deleted')
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

  def preload_exercise_associations
    return unless current_user&.teacher?
    @activity = Activity.includes(
      column_matchings:    :matching_pairs,
      paragraph_orderings: :paragraph_sentences
    ).find(@activity.id)
  end

  def find_quiz_attempt
    attempt = QuizAttempt.find_by(id: session[:quiz_attempt_id]) if session[:quiz_attempt_id].present?
    attempt ||= current_user&.quiz_attempts&.where(activity_id: @activity.id)&.order(created_at: :desc)&.first
    attempt
  end

  def activity_params
    params.require(:activity).permit(:title, :description, :level, :media_url, :video_url, :explanation_text, :statement, :audio_file, :image_file, :video_file)
  end
  
  def authorize_teacher
    unless current_user&.teacher?
      redirect_to root_path, alert: "Acesso restrito a professores."
    end
  end
end
