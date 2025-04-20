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
    @questions = Rails.cache.fetch(["activity_questions", @activity.id, @activity.updated_at.to_i], expires_in: 1.hour) do
      @activity.questions.to_a
    end
  end

  def submit_quiz
    begin
      @activity = Activity.find(params[:id])
      @questions = @activity.questions
      
      # Logs detalhados para debug em produção
      Rails.logger.info "=== SUBMIT QUIZ DEBUG ==="
      Rails.logger.info "Activity ID: #{@activity.id}"
      Rails.logger.info "Activity Questions Count: #{@questions.count}"
      Rails.logger.info "Params recebidos: #{params.to_json}"
      
      # Processa os parâmetros para extrair as respostas
      answers = params[:answers] || {}
      Rails.logger.info "Respostas extraídas: #{answers.to_json}"
      
      Rails.logger.info "Iniciando processamento de respostas para atividade #{@activity.id}"
      
      # Verifica se há perguntas antes de processar
      if @questions.empty?
        redirect_to resolve_quiz_activity_path(@activity, locale: I18n.locale), alert: t('messages.no_questions')
        return
      end
      
      # Processamento otimizado: Pré-carrega todas as questões de uma vez
      question_ids = @questions.pluck(:id)
      results = {}
      total_correct = 0
      
      # Processamento em batch para evitar memory bloat
      question_ids.each_slice(10) do |batch_ids|
        # Carregar apenas os campos necessários para as questões no batch atual
        batch_questions = Question.where(id: batch_ids).select(:id, :content, :question_type, :correct_answer)
        
        # Processar cada questão no batch
        batch_questions.each do |question|
          # Otimização: transformar em string apenas uma vez
          question_id_str = question.id.to_s
          given_answer = answers[question_id_str]
          correct_answer = question.correct_answer
          
          # Inicializar resultado padrão
          is_correct = false
          
          # Otimização: extrair método para processamento específico
          is_correct = process_answer(question.question_type, given_answer, correct_answer)
          
          # Incrementar contador se correto
          total_correct += 1 if is_correct
          
          # Armazenar resultados
          results[question.id] = {
            "question_text" => question.content,
            "question_type" => question.question_type,
            "given_answer" => given_answer.presence || t('quiz.not_answered'),
            "correct_answer" => correct_answer,
            "is_correct" => is_correct
          }
        end
      end
      
      Rails.logger.info "Respostas processadas com sucesso: #{total_correct} de #{@questions.count} corretas"
      
      # Cálculo do score
      score = @questions.count.positive? ? ((total_correct.to_f / @questions.count) * 100).round(2) : 0
      
      # Preparar o hash de resultados no formato exato que a view espera
      quiz_results_data = {
        "activity_id" => @activity.id,
        "results" => results,
        "score" => score,
        "total_correct" => total_correct,
        "total_questions" => @questions.count,
        "submitted_at" => Time.current
      }
      
      # DEBUG: Salvar os resultados na sessão para todos os casos
      session[:quiz_results] = quiz_results_data
      Rails.logger.info "DEBUG: Salvando resultados na sessão: activity_id=#{quiz_results_data['activity_id']}, score=#{quiz_results_data['score']}"
      
      # Criar ou atualizar a tentativa
      if current_user
        @quiz_attempt = QuizAttempt.find_or_initialize_by(
          user_id: current_user.id, 
          activity_id: @activity.id
        )
        
        @quiz_attempt.score = score
        @quiz_attempt.results = quiz_results_data # Usar o hash completo para garantir consistência
        @quiz_attempt.submitted_at = Time.current
        
        # Salvar resultados no banco de dados
        if @quiz_attempt.save
          Rails.logger.info "Tentativa de quiz salva com sucesso para usuário #{current_user.id}"
          redirect_to quiz_results_activity_path(@activity, locale: I18n.locale), 
                     notice: t('quiz.success', score: score)
        else
          Rails.logger.error "Erro ao salvar tentativa: #{@quiz_attempt.errors.full_messages.join(', ')}"
          flash[:alert] = t('quiz.error')
          redirect_to resolve_quiz_activity_path(@activity, locale: I18n.locale)
        end
      else
        # Para usuários não autenticados, apenas redirecionar
        redirect_to quiz_results_activity_path(@activity, locale: I18n.locale), notice: t('quiz.success', score: score)
      end
    rescue StandardError => e
      # Log detalhado do erro para diagnóstico
      Rails.logger.error "Erro ao processar quiz: #{e.class.name} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      # Resposta amigável ao usuário com mais detalhes
      flash[:alert] = "Erro ao processar quiz: #{e.class.name} - #{e.message}"
      redirect_to resolve_quiz_activity_path(@activity, locale: I18n.locale)
    end
  end
  
  # Método auxiliar para processar respostas de diferentes tipos
  def process_answer(question_type, given_answer, correct_answer)
    case question_type
    when 'multiple_choice', 'fill_in_blank'
      # Para escolha múltipla e preenchimento de lacunas, a resposta deve corresponder exatamente
      given_answer.present? && given_answer.to_s.strip == correct_answer.to_s.strip
    when 'order_sentences'
      process_order_sentences_answer(given_answer, correct_answer)
    else
      false
    end
  rescue => e
    Rails.logger.error "Erro ao processar resposta: #{e.message}"
    false
  end
  
  # Método específico para processar respostas de ordenação
  def process_order_sentences_answer(given_answer, correct_answer)
    return false unless given_answer.present?
    
    # Log para debug
    Rails.logger.debug "Processando resposta de ordenação: '#{given_answer}' vs '#{correct_answer}'"
    
    # A resposta sempre vem com formato de pipe agora que usamos select boxes
    # Comparação direta é suficiente
    given_answer.to_s == correct_answer.to_s
  end

  def quiz_results
    @activity = Activity.find(params[:id])
    
    # Debug: Verificar se há dados na sessão
    if session[:quiz_results].present?
      Rails.logger.info "DEBUG: Dados na sessão: #{session[:quiz_results].inspect}"
    else
      Rails.logger.info "DEBUG: Nenhum dado encontrado na sessão para quiz_results"
    end
    
    # Primeiramente, tentar obter da sessão (para compatibilidade)
    if session[:quiz_results].present? && session[:quiz_results]["activity_id"].to_s == @activity.id.to_s
      Rails.logger.info "DEBUG: Usando resultados da sessão"
      @quiz_results = session[:quiz_results]
    else
      Rails.logger.info "DEBUG: Tentando obter resultados do banco de dados"
      # Se não estiver na sessão, procurar no banco de dados
      @quiz_attempt = current_user.quiz_attempts.where(activity_id: @activity.id).order(created_at: :desc).first
      
      if @quiz_attempt
        Rails.logger.info "DEBUG: Encontrada tentativa para o usuário #{current_user.id}, score: #{@quiz_attempt.score}"
        # Usar os resultados do banco de dados
        @quiz_results = @quiz_attempt.results
        
        # Garantir que os dados têm o formato correto
        unless @quiz_results.key?("total_questions")
          # Se os dados estiverem em formato antigo, converter para novo formato
          Rails.logger.info "DEBUG: Convertendo formato antigo de resultados para novo formato"
          @quiz_results = {
            "activity_id" => @activity.id,
            "results" => @quiz_results,
            "score" => @quiz_attempt.score,
            "total_correct" => @quiz_results.values.count { |r| r["is_correct"] },
            "total_questions" => @quiz_results.size,
            "submitted_at" => @quiz_attempt.submitted_at
          }
        end
      else
        Rails.logger.info "DEBUG: Nenhuma tentativa encontrada para o usuário #{current_user.id}"
        # Se não encontrar nem na sessão nem no banco de dados, redirecionar para resolver o quiz
        redirect_to resolve_quiz_activity_path(@activity, locale: I18n.locale), alert: t('messages.answer_quiz_first')
        return
      end
    end
    
    # Carregar as questões para correspondência com os resultados
    @questions = @activity.questions.index_by(&:id)
    
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
