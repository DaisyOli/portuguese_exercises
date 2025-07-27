class ActivitiesController < ApplicationController
  require 'timeout'
  require_relative '../services/quiz_submission_service'
  require_relative '../services/activities_index_service'
  include QuizManagement
  
  before_action :authenticate_user!
  before_action :set_activity, only: [:show, :edit, :update, :destroy, :resolve_quiz, :submit_quiz, :quiz_results, :clear_statement, :clear_media, :clear_explanation, :clear_attempt_history]
  before_action :authorize_teacher, only: [:new, :create, :edit, :update, :destroy]

  def index
    @activities = Activity.all

    # Aplicar filtros
    @activities = @activities.where(level: params[:level]) if params[:level].present?
    @activities = @activities.where("title ILIKE ?", "%#{params[:search]}%") if params[:search].present?

    # Aplicar ordenação
    case params[:sort]
    when 'antigos'
      @activities = @activities.order(created_at: :asc)
    when 'titulo'
      @activities = @activities.order(title: :asc)
    when 'tentativas'
      @activities = @activities.left_joins(:quiz_attempts)
                             .group('activities.id')
                             .order('COUNT(quiz_attempts.id) DESC')
    else # 'recentes' ou padrão
      @activities = @activities.order(created_at: :desc)
    end

    # Aplicar paginação
    @activities = @activities.page(params[:page]).per(12)

    # Carregar métricas para cada atividade
    @activities = @activities.includes(:quiz_attempts)
    
    # REFATORADO: Usando service para organizar a lógica
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
    
    if current_user.role == "student"
      # Redirecionamento direto para resolver o quiz
      redirect_to resolve_quiz_activity_path(@activity)
    end
  end

  def resolve_quiz
    @questions = load_questions
    
    # NOVA FUNCIONALIDADE: Verificar se devemos mostrar o score
    if params[:show_score] == 'true' && session[:quiz_attempt_id].present?
      @quiz_attempt = QuizAttempt.find_by(id: session[:quiz_attempt_id])
      if @quiz_attempt && @quiz_attempt.activity_id == @activity.id
        @show_score = true
        @score = @quiz_attempt.score
        @total_correct = @quiz_attempt.results["total_correct"]
        @total_questions = @quiz_attempt.results["total_questions"]
      end
    else
      # MELHORIA: Limpar dados da sessão quando não está mostrando score (modo refazer)
      session.delete(:show_score_data) if session[:show_score_data]&.dig("activity_id") == @activity.id
    end
  end

  def submit_quiz
    # REFATORADO: Usando service para processar submission
    result = QuizSubmissionService.new(
      activity: @activity,
      user: current_user,
      params: params,
      session: session
    ).call

    # NOVA FUNCIONALIDADE: Armazenar dados do score na sessão para exibir na resolve_quiz
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

    # CÓDIGO ORIGINAL MANTIDO COMO BACKUP (comentado):
    # begin
    #   @activity = Activity.find(params[:id])
    #   @questions = @activity.questions
    #   
    #   # Verificar se já existe uma tentativa recente para este quiz
    #   recent_attempt = current_user&.quiz_attempts&.where(activity_id: @activity.id)&.where('created_at > ?', 30.minutes.ago)&.order(created_at: :desc)&.first
    #
    #   # Inicializar arrays para capturar questões e respostas
    #   results = {}
    #   total_score = 0
    #   
    #   # Obter todas as formas de respostas
    #   raw_answers = params[:answers_raw] || {}
    #   alt_answers = params[:answers_alt] || {}
    #   order_values = params[:answers_order] || {}
    #   
    #   # Nova abordagem: processar frases separadas
    #   sentences_answers = params[:answers_sentences] || {}
    #   
    #   # Processar cada questão
    #   @questions.each do |question|
    #     # [... resto da lógica original comentada ...]
    #   end
    # rescue => e
    #   # [... resto do tratamento de erro original comentado ...]
    # end
  end

  def quiz_results
    begin
      @activity = Activity.find_by!(slug: params[:slug])
      
      # Tentar obter a tentativa a partir do ID na sessão
      if session[:quiz_attempt_id].present?
        @quiz_attempt = QuizAttempt.find_by(id: session[:quiz_attempt_id])
        Rails.logger.info "Recuperando tentativa pelo ID da sessão: #{session[:quiz_attempt_id]}"
      end
      
      # Se não encontrar pelo ID na sessão, buscar a última tentativa do usuário
      if @quiz_attempt.nil? && current_user
        @quiz_attempt = current_user.quiz_attempts.where(activity_id: @activity.id).order(created_at: :desc).first
        Rails.logger.info "Recuperando última tentativa do usuário para atividade #{@activity.id}: #{@quiz_attempt&.id}"
      end
      
      if @quiz_attempt.present?
        # Log do formato original no banco de dados
        Rails.logger.info "Formato dos resultados no banco de dados: #{@quiz_attempt.results.class.name}"
        Rails.logger.info "Dados brutos: #{@quiz_attempt.results.inspect.truncate(500)}"
        
        # Usar os resultados do banco de dados
        @quiz_results = @quiz_attempt.results
        
        # Garantir que os dados têm o formato correto
        unless @quiz_results.key?("total_questions")
          # Se os dados estiverem em formato antigo, converter para novo formato
          Rails.logger.info "Convertendo formato antigo de resultados para novo formato"
          
          if @quiz_results.is_a?(Hash) && @quiz_results.values.any? { |v| v.is_a?(Hash) && v["is_correct"] }
            # Formato antigo com resultados individuais
            @quiz_results = {
              "activity_id" => @activity.id,
              "results" => @quiz_results,
              "score" => @quiz_attempt.score,
              "total_correct" => @quiz_results.values.count { |r| r["is_correct"] },
              "total_questions" => @quiz_results.size,
              "submitted_at" => @quiz_attempt.submitted_at
            }
          else
            # Formato totalmente inválido, criar um fallback
            @quiz_results = {
              "activity_id" => @activity.id,
              "results" => {},
              "score" => @quiz_attempt.score || 0,
              "total_correct" => 0,
              "total_questions" => 0,
              "submitted_at" => @quiz_attempt.submitted_at || Time.current,
              "data_recovery" => true
            }
          end
        end
      else
        # Se não encontrar tentativa, redirecionar para resolver o quiz
        redirect_to resolve_quiz_activity_path(@activity, locale: I18n.locale), alert: t('messages.answer_quiz_first')
        return
      end
      
      # Verificação final de segurança dos dados
      unless @quiz_results.is_a?(Hash) && @quiz_results["results"].is_a?(Hash)
        Rails.logger.error "Formato de dados inválido, criando estrutura de fallback"
        # Criar estrutura de fallback
        @quiz_results = {
          "activity_id" => @activity.id,
          "results" => {},
          "score" => @quiz_attempt&.score || 0,
          "total_correct" => 0,
          "total_questions" => 0,
          "submitted_at" => Time.current,
          "fallback_final" => true
        }
      end
      
      # Garantir que resultados é sempre um hash para evitar erros de renderização
      @quiz_results["results"] = {} unless @quiz_results["results"].is_a?(Hash)
      
      # Carregar as questões para correspondência com os resultados
      @questions = @activity.questions.index_by(&:id)
      
      # Garantir que cada resultado tenha todos os dados necessários
      @quiz_results["results"].each do |question_id, result|
        # Complementar dados ausentes se necessário
        question = @questions[question_id.to_i]
        
        if question.present?
          # Garantir que temos texto da questão
          result["question_text"] = question.content unless result["question_text"].present?
          
          # Garantir que temos o tipo da questão
          result["question_type"] = question.question_type unless result["question_type"].present?
          
          # Garantir que temos a resposta correta
          result["correct_answer"] = question.correct_answer unless result["correct_answer"].present?
        end
        
        # Garantir que temos a resposta dada
        result["given_answer"] = t('quiz.not_answered') unless result["given_answer"].present?
      end
      
      # Adicionar variável javascript com os resultados para debug
      @debug_results_json = @quiz_results.to_json
      
      render 'quiz_results'
    rescue => e
      Rails.logger.error "Erro ao mostrar resultados: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      redirect_to activities_path, alert: "Ocorreu um erro ao exibir os resultados. Tente novamente."
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
    if @activity.teacher == current_user
      # Log para debug
      Rails.logger.info "Executando clear_media para activity #{@activity.id}. Método HTTP: #{request.method}"
      
      # Limpar a media_url
      if @activity.update(media_url: nil)
        Rails.logger.info "Media limpa com sucesso para activity #{@activity.id}"
        redirect_to activity_path(@activity, locale: I18n.locale, ultima_acao: 'conteudo_excluido'), notice: t('messages.media_deleted')
      else
        Rails.logger.error "Falha ao limpar media para activity #{@activity.id}: #{@activity.errors.full_messages.join(', ')}"
        redirect_to @activity, alert: "Erro ao remover a mídia. #{@activity.errors.full_messages.join(', ')}"
      end
    else
      redirect_to @activity, alert: "Você não tem permissão para remover a mídia."
    end
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

  # Método para exibir os resultados após submissão do quiz
  def result_quiz
    @activity = Activity.find_by!(slug: params[:slug])
    
    # Tenta encontrar a tentativa pelo ID ou pegar a última do usuário atual
    if params[:attempt_id].present?
      @quiz_attempt = QuizAttempt.find_by(id: params[:attempt_id])
    elsif current_user
      @quiz_attempt = current_user.quiz_attempts.where(activity_id: @activity.id).order(created_at: :desc).first
    end
    
    # Fallback para resultados da sessão se não houver tentativa salva
    if @quiz_attempt
      # Para tentativas salvas, redirecionar para a página de resultados existente
      redirect_to quiz_results_activity_path(@activity, locale: I18n.locale)
      return
    elsif session[:quiz_results]
      if session[:quiz_results][:activity_id].to_i == @activity.id.to_i
        # Se temos resultados na sessão, redirecionar para a página de resultados
        redirect_to quiz_results_activity_path(@activity, locale: I18n.locale)
        return
      else
        redirect_to resolve_quiz_activity_path(@activity, locale: I18n.locale), alert: t('quiz.no_results')
        return
      end
    else
      redirect_to resolve_quiz_activity_path(@activity, locale: I18n.locale), alert: t('quiz.no_results')
      return
    end
  end

  private

  def set_activity
    @activity = Activity.find_by!(slug: params[:slug])
  end

  def activity_params
    params.require(:activity).permit(:title, :description, :level, :media_url, :explanation_text, :statement)
  end
  
  def load_completed_exercises
    # Inicializar array de exercícios concluídos na sessão se não existir
    session[:completed_quizzes] ||= []
    
    # Carregar todos os quiz_attempts do usuário atual
    completed_activities = current_user.quiz_attempts
                                     .select(:activity_id)
                                     .distinct
                                     .pluck(:activity_id)
    
    # Atualizar a sessão com os IDs de atividades concluídas
    completed_activities.each do |activity_id|
      session[:completed_quizzes] << activity_id unless session[:completed_quizzes].include?(activity_id)
    end
  end

  def authorize_teacher
    unless current_user&.teacher?
      redirect_to root_path, alert: "Acesso restrito a professores."
    end
  end
end
