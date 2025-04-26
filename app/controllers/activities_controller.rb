class ActivitiesController < ApplicationController
  require 'timeout'
  before_action :authenticate_user!
  before_action :set_activity, only: [:show, :edit, :update, :destroy, :resolve_quiz, :submit_quiz, :quiz_results, :clear_statement, :clear_media, :clear_explanation, :clear_attempt_history]

  def index
    if params[:level].present?
      @activities = Rails.cache.fetch(["activities", params[:level], current_user.id], expires_in: 1.hour) do
        Activity.where(level: params[:level]).to_a
      end
      @current_level = params[:level]
      
      # Buscar os melhores resultados para o estudante
      if current_user.student?
        @best_attempts = Rails.cache.fetch(["best_attempts", current_user.id], expires_in: 30.minutes) do
          attempts = current_user.quiz_attempts.where(activity_id: @activities.map(&:id))
                               .group(:activity_id)
                               .select('activity_id, MAX(score) as max_score')
          
          attempts.each_with_object({}) do |attempt, hash|
            hash[attempt.activity_id] = attempt.max_score
          end
        end
      end
    else
      @activities = Rails.cache.fetch(["all_activities"], expires_in: 1.hour) do
        Activity.all.to_a
      end
      
      @activities_by_level = Rails.cache.fetch(["activities_by_level"], expires_in: 1.hour) do
        Activity.all.group_by(&:level)
      end
    end
  end

  def show
    @questions = Rails.cache.fetch(["activity_questions", @activity.id, @activity.updated_at.to_i], expires_in: 1.hour) do
      @activity.questions.to_a
    end
    
    if current_user.role == "student"
      # Redirecionamento direto para resolver o quiz
      redirect_to resolve_quiz_activity_path(@activity)
    end
  end

  def resolve_quiz
    # Obter questões sem usar o cache para verificar se é um problema de cache
    if params[:skip_cache] == "true"
      @questions = @activity.questions.to_a
      Rails.logger.debug "Carregando questões sem cache: #{@questions.count} questões encontradas"
    else
      @questions = Rails.cache.fetch(["activity_questions", @activity.id, @activity.updated_at.to_i], expires_in: 1.hour) do
        @activity.questions.to_a
      end
    end
    
    # Logging para debug do problema de questões não aparecendo
    Rails.logger.debug "=== DIAGNÓSTICO DE EXIBIÇÃO DE QUESTÕES ==="
    Rails.logger.debug "Atividade ID: #{@activity.id}, Título: #{@activity.title}"
    Rails.logger.debug "Total de questões carregadas: #{@questions.count}"
    Rails.logger.debug "Cache utilizado: #{params[:skip_cache] != 'true'}"
    @questions.each_with_index do |q, i|
      Rails.logger.debug "Questão #{i+1}: ID=#{q.id}, Tipo=#{q.question_type}, Conteúdo=#{q.content.truncate(50) if q.content.present?}"
    end
    Rails.logger.debug "=========================================="
  end

  def submit_quiz
    begin
      @activity = Activity.find(params[:id])
      @questions = @activity.questions
      
      # Verificar se já existe uma tentativa recente para este quiz
      recent_attempt = current_user&.quiz_attempts&.where(activity_id: @activity.id)&.where('created_at > ?', 30.minutes.ago)&.order(created_at: :desc)&.first

      # Inicializar arrays para capturar questões e respostas
      results = {}
      total_score = 0
      
      # Obter todas as formas de respostas
      raw_answers = params[:answers_raw] || {}
      alt_answers = params[:answers_alt] || {}
      order_values = params[:answers_order] || {}
      
      # Nova abordagem: processar frases separadas
      sentences_answers = params[:answers_sentences] || {}
      
      # Processar cada questão
      @questions.each do |question|
        # Obter a resposta dada pelo usuário
        given_answer = params[:answers][question.id.to_s]
        
        # Obter resposta correta
        correct_answer = question.correct_answer
        
        # Processamento baseado no tipo de questão
        is_correct = false 
        
        begin
          # Processamento específico para questões fill_in_blank
          if question.fill_in_blank?
            # Normalizar resposta: remover espaços extras, converter para minúsculas e remover acentos
            normalized_given = given_answer.to_s.strip.downcase.gsub(/\s+/, '')
            normalized_correct = correct_answer.to_s.strip.downcase.gsub(/\s+/, '')
            
            # Remover acentos usando transliterate
            normalized_given = I18n.transliterate(normalized_given)
            normalized_correct = I18n.transliterate(normalized_correct)
            
            # Comparar respostas normalizadas
            is_correct = given_answer.present? && normalized_given == normalized_correct
          else
            # Processamento para outros tipos de questão - mantido idêntico
            is_correct = given_answer.present? && given_answer.to_s.strip == correct_answer.to_s.strip
          end
          
          results[question.id] = {
            "is_correct" => is_correct,
            "question_text" => question.content,
            "question_type" => question.question_type,
            "given_answer" => given_answer.present? ? given_answer.to_s.strip : t('quiz.not_answered'),
            "correct_answer" => correct_answer,
            "raw_answer" => given_answer.to_s.strip
          }
          
          # Incrementar contador
          total_score += 1 if is_correct
          
        rescue => e
          # Log detalhado de erros
          Rails.logger.error "ERRO ao processar questão #{question.id}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          
          # Criar um resultado de erro
          results[question.id] = {
            "is_correct" => false,
            "question_text" => question.content,
            "question_type" => question.question_type,
            "given_answer" => "ERRO: #{e.message}",
            "correct_answer" => correct_answer,
            "error" => true
          }
        end
      end
      
      # Calcular score
      score = @questions.count.positive? ? ((total_score.to_f / @questions.count) * 100).round(2) : 0
      
      # Hash simplificado de resultados
      quiz_results_data = {
        "activity_id" => @activity.id,
        "results" => results,
        "score" => score,
        "total_correct" => total_score,
        "total_questions" => @questions.count,
        "submitted_at" => Time.current
      }
      
      # Log resumo do processamento
      Rails.logger.info "Processamento finalizado: #{total_score} corretas de #{@questions.count} questões (#{score}%)"
      
     
      
      
      # Em vez de salvar na sessão, armazenar apenas no banco de dados
      # e guardar apenas o ID da tentativa na sessão
      if current_user
        @quiz_attempt = QuizAttempt.find_or_initialize_by(
          user_id: current_user.id, 
          activity_id: @activity.id
        )
        
        @quiz_attempt.score = score
        @quiz_attempt.results = quiz_results_data
        @quiz_attempt.submitted_at = Time.current
        
        if @quiz_attempt.save
          # Armazenar apenas o ID da tentativa na sessão, evitando o CookieOverflow
          session[:quiz_attempt_id] = @quiz_attempt.id
          session[:last_quiz_score] = score
          
          redirect_to quiz_results_activity_path(@activity, locale: I18n.locale), 
                    notice: t('quiz.success', score: score)
        else
          flash[:alert] = t('quiz.error')
          redirect_to quiz_results_activity_path(@activity, locale: I18n.locale)
        end
      else
        # Para usuários não autenticados - criar uma tentativa temporária
        # sem associação a um usuário
        @quiz_attempt = QuizAttempt.new(
          activity_id: @activity.id,
          score: score,
          results: quiz_results_data,
          submitted_at: Time.current
        )
        
        if @quiz_attempt.save
          # Armazenar apenas o ID da tentativa na sessão
          session[:quiz_attempt_id] = @quiz_attempt.id
          session[:last_quiz_score] = score
          
          redirect_to quiz_results_activity_path(@activity, locale: I18n.locale), 
                    notice: t('quiz.success', score: score)
        else
          flash[:alert] = t('quiz.error')
          redirect_to activities_path
        end
      end
      
    rescue => e
      # Log do erro
      Rails.logger.error "ERRO: #{e.class.name} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      # Fallback
      begin
        activity_id = params[:id].to_i
        redirect_to activities_path, alert: "Ocorreu um erro ao processar o quiz. Tente novamente com menos questões."
      rescue => final_e
        redirect_to activities_path, alert: "Erro no processamento."
      end
    end
  end

  def quiz_results
    begin
      @activity = Activity.find(params[:id])
      
      # Verificar se devemos desativar as correções de emergência
      @disable_emergency_fixes = params[:raw_display] == "true"
      
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

  def clear_attempt_history
    @activity = Activity.find(params[:id])
    
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
    @activity = Activity.find(params[:id])
    
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
    @activity = Activity.find(params[:id])
  end

  def activity_params
    params.require(:activity).permit(:title, :description, :level, :media_url, :explanation_text, :statement)
  end
end
