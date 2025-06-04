# app/services/quiz_submission_service.rb
class QuizSubmissionService
  attr_reader :activity, :user, :params, :session

  def initialize(activity:, user:, params:, session:)
    @activity = activity
    @user = user
    @params = params
    @session = session
  end

  def call
    begin
      process_quiz_submission
    rescue => e
      handle_error(e)
    end
  end

  private

  def process_quiz_submission
    @questions = @activity.questions
    
    # Verificar se já existe uma tentativa recente para este quiz
    recent_attempt = @user&.quiz_attempts&.where(activity_id: @activity.id)&.where('created_at > ?', 30.minutes.ago)&.order(created_at: :desc)&.first

    # Inicializar arrays para capturar questões e respostas
    results = {}
    total_score = 0
    
    # Obter todas as formas de respostas (mantendo exatamente como no controller)
    raw_answers = @params[:answers_raw] || {}
    alt_answers = @params[:answers_alt] || {}
    order_values = @params[:answers_order] || {}
    sentences_answers = @params[:answers_sentences] || {}
    
    # Processar cada questão (lógica exata do controller)
    @questions.each do |question|
      # Obter a resposta dada pelo usuário
      given_answer = @params[:answers][question.id.to_s]
      
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
          
          # Log dos valores normalizados
          Rails.logger.info "RESPOSTA DEBUG: Normalizado dado='#{normalized_given}'"
          Rails.logger.info "RESPOSTA DEBUG: Normalizado correto='#{normalized_correct}'"
          Rails.logger.info "RESPOSTA DEBUG: São iguais? #{normalized_given == normalized_correct}"
          
          # Verificar se a resposta foi preenchida
          if given_answer.blank?
            Rails.logger.info "RESPOSTA DEBUG: Resposta em branco!"
            is_correct = false
          else
            # Comparar respostas normalizadas
            is_correct = normalized_given == normalized_correct
            Rails.logger.info "RESPOSTA DEBUG: Resultado da comparação: #{is_correct}"
          end
        else
          # Processamento para outros tipos de questão - mantido idêntico
          is_correct = given_answer.present? && given_answer.to_s.strip == correct_answer.to_s.strip
        end
        
        results[question.id] = {
          "is_correct" => is_correct,
          "question_text" => question.content,
          "question_type" => question.question_type,
          "given_answer" => given_answer.present? ? given_answer.to_s.strip : I18n.t('quiz.not_answered'),
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
    
    # Salvar tentativa e gerenciar sessão
    save_quiz_attempt(quiz_results_data, score)
  end

  def save_quiz_attempt(quiz_results_data, score)
    if @user
      @quiz_attempt = QuizAttempt.find_or_initialize_by(
        user_id: @user.id, 
        activity_id: @activity.id
      )
      
      @quiz_attempt.score = score
      @quiz_attempt.results = quiz_results_data
      @quiz_attempt.submitted_at = Time.current
      
      if @quiz_attempt.save
        # Armazenar apenas o ID da tentativa na sessão, evitando o CookieOverflow
        @session[:quiz_attempt_id] = @quiz_attempt.id
        @session[:last_quiz_score] = score
        
        # Atualizar a lista de quizzes completados na sessão
        @session[:completed_quizzes] ||= []
        @session[:completed_quizzes] << @activity.id unless @session[:completed_quizzes].include?(@activity.id)
        
        # NOVA FUNCIONALIDADE: Retornar para resolve_quiz com dados do score
        return {
          success: true,
          quiz_attempt: @quiz_attempt,
          show_score: true,
          score: score,
          total_correct: quiz_results_data["total_correct"],
          total_questions: quiz_results_data["total_questions"],
          redirect_path: [:resolve_quiz, @activity, { locale: I18n.locale, show_score: true }],
          notice: nil # Removemos a notice para não mostrar alert
        }
      else
        return {
          success: false,
          redirect_path: [:resolve_quiz, @activity, { locale: I18n.locale }],
          alert: I18n.t('quiz.error')
        }
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
        @session[:quiz_attempt_id] = @quiz_attempt.id
        @session[:last_quiz_score] = score
        
        # Atualizar a lista de quizzes completados na sessão
        @session[:completed_quizzes] ||= []
        @session[:completed_quizzes] << @activity.id unless @session[:completed_quizzes].include?(@activity.id)
        
        # NOVA FUNCIONALIDADE: Retornar para resolve_quiz com dados do score
        return {
          success: true,
          quiz_attempt: @quiz_attempt,
          show_score: true,
          score: score,
          total_correct: quiz_results_data["total_correct"],
          total_questions: quiz_results_data["total_questions"],
          redirect_path: [:resolve_quiz, @activity, { locale: I18n.locale, show_score: true }],
          notice: nil # Removemos a notice para não mostrar alert
        }
      else
        return {
          success: false,
          redirect_path: [:activities],
          alert: I18n.t('quiz.error')
        }
      end
    end
  end

  def handle_error(e)
    # Log do erro
    Rails.logger.error "ERRO: #{e.class.name} - #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    # Retornar resposta de erro
    {
      success: false,
      redirect_path: [:activities],
      alert: I18n.t('quiz.error')
    }
  end
end 