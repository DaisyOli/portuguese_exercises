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
    # Adiciona um timeout para evitar que o Heroku mate o processo
    Timeout.timeout(25) do  # 25 segundos é um valor seguro abaixo do limite de 30s do Heroku
      begin
        @activity = Activity.find(params[:id])
        @questions = @activity.questions
        
        # Processa os parâmetros para extrair as respostas
        answers = params[:answers] || {}
        
        Rails.logger.info "Iniciando processamento de respostas para atividade #{@activity.id}"
        
        results = {}
        total_correct = 0
        
        # Verifica se há perguntas antes de processar
        if @questions.empty?
          redirect_to resolve_quiz_activity_path(@activity), alert: t('messages.no_questions')
          return
        end
        
        # Otimização: Processar questões em lotes menores para evitar bloqueio longo
        @questions.find_each(batch_size: 5) do |question|
          Rails.logger.debug "Processando questão #{question.id} (tipo: #{question.question_type})"
          
          given_answer = answers[question.id.to_s]
          correct_answer = question.correct_answer
          
          is_correct = false
          
          # Processa diferentes tipos de questões
          begin
            case question.question_type
            when 'multiple_choice'
              is_correct = given_answer.present? && given_answer.to_s.strip == correct_answer.to_s.strip
            when 'fill_in_blank'
              is_correct = given_answer.present? && given_answer.to_s.strip == correct_answer.to_s.strip
            when 'order_sentences'
              # Tratamento especial para questões de ordenação
              if given_answer.present?
                # Verifica se a resposta está no formato esperado (valores separados por |)
                if given_answer.to_s.include?('|')
                  is_correct = given_answer.to_s == correct_answer.to_s
                else
                  # Fallback para o caso do Sortable.js não funcionar corretamente
                  # Verifica apenas se os elementos estão presentes, mesmo que fora de ordem
                  # Assim o aluno não é penalizado por problemas técnicos
                  Rails.logger.warn "Formato de resposta inesperado para questão de ordenação: #{given_answer}"
                  
                  # Verifica se todas as frases esperadas estão presentes na resposta
                  expected_sentences = correct_answer.to_s.split('|')
                  is_correct = expected_sentences.all? { |sentence| given_answer.to_s.include?(sentence) }
                end
              end
            end
          rescue => e
            Rails.logger.error "Erro ao processar questão #{question.id}: #{e.message}"
            # Continua processando outras questões mesmo com erro em uma
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
        
        Rails.logger.info "Respostas processadas com sucesso: #{total_correct} de #{@questions.count} corretas"
        
        # Cálculo do score
        score = @questions.count.positive? ? ((total_correct.to_f / @questions.count) * 100).round(2) : 0
        
        # Preparar o hash de resultados 
        quiz_results_data = {
          activity_id: @activity.id,
          results: results,
          score: score,
          total_correct: total_correct,
          total_questions: @questions.count
        }
        
        # Armazenar na sessão para compatibilidade com código existente
        session[:quiz_results] = quiz_results_data
        
        # Salvar no banco de dados para persistência
        @quiz_attempt = current_user.quiz_attempts.create!(
          activity: @activity,
          score: score,
          results: quiz_results_data,
          submitted_at: Time.current
        )
        
        respond_to do |format|
          format.html { redirect_to quiz_results_activity_path(@activity), notice: t('messages.quiz_submitted') }
          format.turbo_stream { redirect_to quiz_results_activity_path(@activity), notice: t('messages.quiz_submitted') }
        end
      rescue ActiveRecord::RecordNotFound => e
        Rails.logger.error "Erro de registro não encontrado: #{e.message}"
        redirect_to activities_path, alert: t('messages.activity_not_found')
      rescue => e
        Rails.logger.error "Erro ao processar quiz: #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}"
        redirect_to resolve_quiz_activity_path(@activity), alert: t('messages.quiz_error')
      end
    end
  rescue Timeout::Error => e
    Rails.logger.error "Timeout ao processar quiz: #{e.message}"
    redirect_to resolve_quiz_activity_path(@activity || params[:id]), alert: t('messages.quiz_timeout')
  end

  def quiz_results
    @activity = Activity.find(params[:id])
    
    # Primeiramente, tentar obter da sessão (para compatibilidade)
    if session[:quiz_results].present? && session[:quiz_results]["activity_id"] == @activity.id
      @quiz_results = session[:quiz_results]
    else
      # Se não estiver na sessão, procurar no banco de dados
      @quiz_attempt = current_user.quiz_attempts.where(activity_id: @activity.id).order(created_at: :desc).first
      
      if @quiz_attempt
        # Formatar os resultados no mesmo formato esperado pela view
        @quiz_results = @quiz_attempt.results
      else
        # Se não encontrar nem na sessão nem no banco de dados, redirecionar para resolver o quiz
        redirect_to resolve_quiz_activity_path(@activity), alert: t('messages.answer_quiz_first')
        return
      end
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

  private

  def set_activity
    @activity = Activity.find(params[:id])
  end

  def activity_params
    params.require(:activity).permit(:title, :description, :level, :media_url, :explanation_text, :statement)
  end
end
