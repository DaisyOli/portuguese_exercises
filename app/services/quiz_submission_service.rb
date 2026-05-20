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
    @sentence_orderings = @activity.sentence_orderings.any? \
      ? @activity.sentence_orderings.includes(:sentence_words).to_a \
      : []

    # Inicializar arrays para capturar questões e respostas
    results = {}
    total_score = 0

    # Processar cada questão
    @questions.each do |question|
      # Obter a resposta dada pelo usuário
      given_answer = @params.dig(:answers, question.id.to_s)
      
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
          
          normalized_given = I18n.transliterate(normalized_given)
          normalized_correct = I18n.transliterate(normalized_correct)

          if given_answer.blank?
            is_correct = false
          else
            is_correct = normalized_given == normalized_correct
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
    
    # Processar exercícios de ordenar palavras
    sentence_ordering_answers = @params[:sentence_ordering_answers] || {}
    @sentence_orderings.each do |ordering|
      given_ids = sentence_ordering_answers[ordering.id.to_s].to_s.split(",")
      is_correct = ordering.check_order(given_ids)
      total_score += 1 if is_correct

      results["sentence_ordering_#{ordering.id}"] = {
        "is_correct" => is_correct,
        "exercise_type" => "sentence_ordering",
        "sentence" => ordering.sentence
      }
    end

    # Calcular score
    total_items = @questions.count + @sentence_orderings.size
    score = total_items.positive? ? ((total_score.to_f / total_items) * 100).round(2) : 0

    # Hash simplificado de resultados
    quiz_results_data = {
      "activity_id" => @activity.id,
      "results" => results,
      "score" => score,
      "total_correct" => total_score,
      "total_questions" => total_items,
      "submitted_at" => Time.current
    }
    
    # Salvar tentativa e gerenciar sessão
    save_quiz_attempt(quiz_results_data, score)
  end

  def save_quiz_attempt(quiz_results_data, score)
    if @user
      @quiz_attempt = QuizAttempt.find_or_initialize_by(
        user_id: @user.id,
        activity_id: @activity.id
      )
      error_path = Rails.application.routes.url_helpers.solve_activity_path(@activity, locale: I18n.locale)
    else
      @quiz_attempt = QuizAttempt.new(activity_id: @activity.id)
      error_path = Rails.application.routes.url_helpers.activities_path
    end

    @quiz_attempt.score = score
    @quiz_attempt.results = quiz_results_data
    @quiz_attempt.submitted_at = Time.current

    if @quiz_attempt.save
      update_session(score)
      success_response(quiz_results_data, score)
    else
      { success: false, redirect_path: error_path, alert: I18n.t('quiz.error') }
    end
  end

  def update_session(score)
    @session[:quiz_attempt_id] = @quiz_attempt.id
    @session[:last_quiz_score] = score
    @session[:completed_quizzes] ||= []
    @session[:completed_quizzes] << @activity.id unless @session[:completed_quizzes].include?(@activity.id)
  end

  def success_response(quiz_results_data, score)
    {
      success: true,
      quiz_attempt: @quiz_attempt,
      show_score: true,
      score: score,
      total_correct: quiz_results_data["total_correct"],
      total_questions: quiz_results_data["total_questions"],
      redirect_path: Rails.application.routes.url_helpers.solve_activity_path(@activity, locale: I18n.locale, show_score: true),
      notice: nil
    }
  end

  def handle_error(e)
    # Log do erro
    Rails.logger.error "ERRO: #{e.class.name} - #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    # Retornar resposta de erro
    {
      success: false,
      redirect_path: Rails.application.routes.url_helpers.activities_path,
      alert: I18n.t('quiz.error')
    }
  end
end 