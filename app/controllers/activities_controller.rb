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
      
      # Logs básicos
      Rails.logger.info "Iniciando processamento para atividade #{@activity.id} com #{@questions.count} questões"
      
      # OTIMIZAÇÃO: Reduzir a quantidade de dados processados
      question_ids = @questions.pluck(:id)
      results = {}
      total_correct = 0
      
      # Simplifique as respostas para processamento mais rápido
      answers = params[:answers] || {}
      
      # Processamento mais eficiente, tudo de uma vez
      all_questions = Question.where(id: question_ids).select(:id, :content, :question_type, :correct_answer).to_a
      question_map = all_questions.index_by(&:id)
      
      # Processar cada resposta - método simplificado
      answers.each do |question_id_str, given_answer|
        question_id = question_id_str.to_i
        question = question_map[question_id]
        
        next unless question # Pula se a questão não existir
        
        # Processamento simplificado
        is_correct = false
        begin
          # Comparação direta para todos os tipos de questão
          is_correct = given_answer.present? && given_answer.to_s.strip == question.correct_answer.to_s.strip
        rescue => e
          Rails.logger.error "Erro ao processar resposta: #{e.message}"
        end
        
        # Incrementar contador
        total_correct += 1 if is_correct
        
        # Armazenar informações completas sobre a questão
        results[question_id] = {
          "is_correct" => is_correct,
          "question_text" => question.content,
          "question_type" => question.question_type,
          "given_answer" => given_answer.present? ? given_answer.to_s.strip : t('quiz.not_answered'),
          "correct_answer" => question.correct_answer
        }
      end
      
      # Calcular score
      score = @questions.count.positive? ? ((total_correct.to_f / @questions.count) * 100).round(2) : 0
      
      # Hash simplificado de resultados
      quiz_results_data = {
        "activity_id" => @activity.id,
        "results" => results,
        "score" => score,
        "total_correct" => total_correct,
        "total_questions" => @questions.count,
        "submitted_at" => Time.current
      }
      
      # Salvar na sessão
      session[:quiz_results] = quiz_results_data
      
      # Salvar no banco de dados de forma eficiente
      if current_user
        @quiz_attempt = QuizAttempt.find_or_initialize_by(
          user_id: current_user.id, 
          activity_id: @activity.id
        )
        
        @quiz_attempt.score = score
        @quiz_attempt.results = quiz_results_data
        @quiz_attempt.submitted_at = Time.current
        
        if @quiz_attempt.save
          redirect_to quiz_results_activity_path(@activity, locale: I18n.locale), 
                    notice: t('quiz.success', score: score)
        else
          flash[:alert] = t('quiz.error')
          redirect_to quiz_results_activity_path(@activity, locale: I18n.locale)
        end
      else
        # Para usuários não autenticados
        redirect_to quiz_results_activity_path(@activity, locale: I18n.locale), 
                   notice: t('quiz.success', score: score)
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
    # Segurança: se não tiver resposta, já retorna falso
    return false if given_answer.blank?
    
    # Log de debug com valores completos
    Rails.logger.debug "Processando resposta de ordenação - Dada: '#{given_answer}' (#{given_answer.class.name}) vs Correta: '#{correct_answer}' (#{correct_answer.class.name})"
    
    # Versão ultra segura - compara strings diretas, sem nenhuma manipulação
    begin
      # Comparação direta como string
      if given_answer.to_s == correct_answer.to_s
        Rails.logger.debug "Resposta exata correspondeu"
        return true
      end
      
      # Se as strings não correspondem exatamente mas dado contém pipe, compare os valores normalizados
      if given_answer.to_s.include?('|')
        # Tente normalizar ambos os lados
        given_items = given_answer.to_s.split('|').map(&:strip)
        correct_items = correct_answer.to_s.split('|').map(&:strip)
        
        # Comparar os arrays
        if given_items == correct_items
          Rails.logger.debug "Normalizado correspondeu"
          return true
        end
      end
      
      # Não corresponde
      Rails.logger.debug "Não correspondeu"
      return false
    rescue => e
      # Se qualquer coisa der errado, log e retorne falso
      Rails.logger.error "Erro ao comparar respostas de ordenação: #{e.message}"
      return false
    end
  end

  def quiz_results
    begin
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
        if current_user
          @quiz_attempt = current_user.quiz_attempts.where(activity_id: @activity.id).order(created_at: :desc).first
          
          if @quiz_attempt
            Rails.logger.info "DEBUG: Encontrada tentativa para o usuário #{current_user.id}, score: #{@quiz_attempt.score}"
            # Usar os resultados do banco de dados com segurança
            begin
              @quiz_results = @quiz_attempt.results
              
              # Garantir que os dados têm o formato correto
              unless @quiz_results.key?("total_questions")
                # Se os dados estiverem em formato antigo, converter para novo formato
                Rails.logger.info "DEBUG: Convertendo formato antigo de resultados para novo formato"
                
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
            rescue => e
              # Se ocorrer algum erro no processamento dos resultados, usar um fallback
              Rails.logger.error "Erro ao processar resultados do banco: #{e.message}"
              @quiz_results = {
                "activity_id" => @activity.id,
                "results" => {},
                "score" => @quiz_attempt.score || 0,
                "total_correct" => 0,
                "total_questions" => 0,
                "submitted_at" => Time.current,
                "fallback" => true
              }
            end
          else
            Rails.logger.info "DEBUG: Nenhuma tentativa encontrada para o usuário #{current_user.id}"
            # Se não encontrar nem na sessão nem no banco de dados, redirecionar para resolver o quiz
            redirect_to resolve_quiz_activity_path(@activity, locale: I18n.locale), alert: t('messages.answer_quiz_first')
            return
          end
        else
          # Caso extremo: usuário não autenticado mas com dados na sessão
          # Criar um resultado temporário para exibição
          Rails.logger.info "DEBUG: Usuário não autenticado, criando resultado temporário"
          @quiz_results = {
            "activity_id" => @activity.id,
            "results" => {},
            "score" => 0,
            "total_correct" => 0,
            "total_questions" => 0,
            "submitted_at" => Time.current,
            "temporary" => true
          }
        end
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
      # Se tudo falhar, redirecionar com uma mensagem amigável
      Rails.logger.error "ERRO NA EXIBIÇÃO DOS RESULTADOS: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      flash[:alert] = "Ocorreu um erro ao exibir os resultados: #{e.message}"
      redirect_to activities_path
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
