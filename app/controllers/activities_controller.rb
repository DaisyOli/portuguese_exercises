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
    
    # Removidas todas as referências a QuizAttempt que não existe mais
  end

  def show
    @questions = @activity.questions
    if current_user.role == "student"
      # Redirecionamento direto para resolver o quiz, sem verificar tentativas anteriores
      redirect_to resolve_quiz_activity_path(@activity)
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
    
    # Mantenha a sessão temporária para compatibilidade com o código existente
    @quiz_results = {
      activity_id: @activity.id,
      results: results,
      score: score,
      total_correct: total_correct,
      total_questions: @questions.count
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
    
    if session[:quiz_results].present? && session[:quiz_results]["activity_id"] == @activity.id
      @quiz_results = session[:quiz_results]
    else
      redirect_to resolve_quiz_activity_path(@activity), alert: t('messages.answer_quiz_first')
      return
    end
    
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
      redirect_to activities_path, alert: t('messages.permission_denied')
      return
    end

    @activity.update(media_url: nil)
    # Redirecionar para a parte superior da página ou para outro conteúdo
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
