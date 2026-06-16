# app/services/quiz_submission_service.rb
require "anthropic"

class QuizSubmissionService
  AI_CORRECTION_SYSTEM = <<~PROMPT
    Você é um avaliador de respostas de estudantes de português como segunda língua.
    Avalie a resposta do aluno de forma construtiva e encorajadora.
    Responda SOMENTE com JSON neste formato exato (sem markdown, sem texto extra):
    {"score": <inteiro de 0 a 100>, "feedback": "<feedback curto em português>"}
    Score 100 = resposta perfeita; 0 = em branco ou completamente errada.
  PROMPT

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
    @paragraph_orderings = @activity.paragraph_orderings.any? \
      ? @activity.paragraph_orderings.includes(:paragraph_sentences).to_a \
      : []
    @column_matchings = @activity.column_matchings.any? \
      ? @activity.column_matchings.includes(:matching_pairs).to_a \
      : []

    results = {}

    # Weighted score (for %) + unweighted counts (for display)
    total_weighted_correct  = 0.0
    total_weighted_possible = 0.0
    total_correct_count     = 0
    total_exercise_count    = 0

    # Processar cada questão
    @questions.each do |question|
      given_answer  = @params.dig(:answers, question.id.to_s)
      correct_answer = question.correct_answer
      is_correct    = false
      skip_score    = false

      begin
        if question.open_ended?
          ai_result = correct_open_ended(question, given_answer)

          if ai_result[:score].nil?
            # IA indisponível — preserva a resposta mas não conta no score
            skip_score = true
            results[question.id] = {
              "is_correct"     => nil,
              "question_text"  => question.content,
              "question_type"  => question.question_type,
              "given_answer"   => given_answer.present? ? given_answer.to_s.strip : I18n.t('quiz.not_answered'),
              "ai_score"       => nil,
              "ai_feedback"    => ai_result[:feedback],
              "ai_unavailable" => true
            }
          else
            is_correct = ai_result[:score] >= 70
            results[question.id] = {
              "is_correct"    => is_correct,
              "question_text" => question.content,
              "question_type" => question.question_type,
              "given_answer"  => given_answer.present? ? given_answer.to_s.strip : I18n.t('quiz.not_answered'),
              "ai_score"      => ai_result[:score],
              "ai_feedback"   => ai_result[:feedback]
            }
          end

        elsif question.fill_in_blank?
          normalized_given   = I18n.transliterate(given_answer.to_s.strip.downcase.gsub(/\s+/, ''))
          normalized_correct = I18n.transliterate(correct_answer.to_s.strip.downcase.gsub(/\s+/, ''))
          is_correct = given_answer.present? && normalized_given == normalized_correct

          results[question.id] = {
            "is_correct"    => is_correct,
            "question_text" => question.content,
            "question_type" => question.question_type,
            "given_answer"  => given_answer.present? ? given_answer.to_s.strip : I18n.t('quiz.not_answered'),
            "correct_answer" => correct_answer,
            "raw_answer"    => given_answer.to_s.strip
          }

        else
          is_correct = given_answer.present? && given_answer.to_s.strip == correct_answer.to_s.strip

          results[question.id] = {
            "is_correct"    => is_correct,
            "question_text" => question.content,
            "question_type" => question.question_type,
            "given_answer"  => given_answer.present? ? given_answer.to_s.strip : I18n.t('quiz.not_answered'),
            "correct_answer" => correct_answer,
            "raw_answer"    => given_answer.to_s.strip
          }
        end

      rescue => e
        Rails.logger.error "ERRO ao processar questão #{question.id}: #{e.message}\n#{e.backtrace.join("\n")}"
        results[question.id] = {
          "is_correct"    => false,
          "question_text" => question.content,
          "question_type" => question.question_type,
          "given_answer"  => "ERRO: #{e.message}",
          "correct_answer" => correct_answer,
          "error"         => true
        }
      end

      next if skip_score

      weight = (question.weight || 1).to_f
      total_weighted_possible += weight
      total_exercise_count    += 1
      if is_correct
        total_weighted_correct += weight
        total_correct_count    += 1
      end
    end

    # Processar exercícios de ordenar palavras
    sentence_ordering_answers = @params[:sentence_ordering_answers] || {}
    @sentence_orderings.each do |ordering|
      given_ids  = sentence_ordering_answers[ordering.id.to_s].to_s.split(",")
      is_correct = ordering.check_order(given_ids)

      total_weighted_possible += 1
      total_exercise_count    += 1
      if is_correct
        total_weighted_correct += 1
        total_correct_count    += 1
      end

      results["sentence_ordering_#{ordering.id}"] = {
        "is_correct"    => is_correct,
        "exercise_type" => "sentence_ordering",
        "sentence"      => ordering.sentence
      }
    end

    # Processar exercícios de ordenar frases
    paragraph_ordering_answers = @params[:paragraph_ordering_answers] || {}
    @paragraph_orderings.each do |ordering|
      given_ids  = paragraph_ordering_answers[ordering.id.to_s].to_s.split(",")
      is_correct = ordering.check_order(given_ids)

      total_weighted_possible += 1
      total_exercise_count    += 1
      if is_correct
        total_weighted_correct += 1
        total_correct_count    += 1
      end

      correct_order = ordering.paragraph_sentences.to_a
                             .sort_by(&:correct_position)
                             .map(&:sentence)

      results["paragraph_ordering_#{ordering.id}"] = {
        "is_correct"    => is_correct,
        "exercise_type" => "paragraph_ordering",
        "title"         => ordering.title.presence || I18n.t('paragraph_orderings.title'),
        "correct_order" => correct_order
      }
    end

    # Processar exercícios de associar colunas
    column_matching_answers = @params[:column_matching_answers] || {}
    @column_matchings.each do |matching|
      answer_string = column_matching_answers[matching.id.to_s].to_s
      is_correct    = matching.check_answer(answer_string)

      total_weighted_possible += 1
      total_exercise_count    += 1
      if is_correct
        total_weighted_correct += 1
        total_correct_count    += 1
      end

      correct_pairs = matching.matching_pairs.order(:position).map { |p| [p.left_item, p.right_item] }

      results["column_matching_#{matching.id}"] = {
        "is_correct"    => is_correct,
        "exercise_type" => "column_matching",
        "title"         => matching.title.presence || I18n.t('column_matchings.title'),
        "correct_pairs" => correct_pairs
      }
    end

    score = total_weighted_possible > 0 \
      ? ((total_weighted_correct / total_weighted_possible) * 100).round(2) \
      : 0

    quiz_results_data = {
      "activity_id"    => @activity.id,
      "results"        => results,
      "score"          => score,
      "total_correct"  => total_correct_count,
      "total_questions" => total_exercise_count,
      "submitted_at"   => Time.current
    }

    save_quiz_attempt(quiz_results_data, score)
  end

  def correct_open_ended(question, given_answer)
    if given_answer.blank?
      return { score: 0, feedback: I18n.t('quiz.not_answered') }
    end

    client = Anthropic::Client.new(api_key: ENV.fetch("ANTHROPIC_API_KEY"))

    rubric_line = question.evaluation_prompt.present? \
      ? "Critérios de avaliação: #{question.evaluation_prompt}\n" \
      : ""

    message = client.messages.create(
      model: :"claude-haiku-4-5",
      max_tokens: 256,
      system_: AI_CORRECTION_SYSTEM,
      messages: [{
        role: "user",
        content: "Questão: #{ActionView::Base.full_sanitizer.sanitize(question.content.to_s)}\n#{rubric_line}Resposta do aluno: #{given_answer.to_s.strip}"
      }]
    )

    text_block = message.content.find { |b| b.type == :text }
    parsed = JSON.parse(text_block.text.strip.gsub(/\A```(?:json)?\s*/i, '').gsub(/\s*```\z/, ''))
    { score: parsed["score"].to_i.clamp(0, 100), feedback: parsed["feedback"].to_s }

  rescue Anthropic::Errors::RateLimitError
    Rails.logger.warn "AI correction rate limited"
    { score: nil, feedback: I18n.t('ai.errors.rate_limit') }
  rescue Anthropic::Errors::APITimeoutError, Anthropic::Errors::APIConnectionError
    Rails.logger.warn "AI correction timeout/connection error"
    { score: nil, feedback: I18n.t('ai.errors.timeout') }
  rescue Anthropic::Errors::APIStatusError => e
    Rails.logger.error "AI correction API error: #{e.message}"
    { score: nil, feedback: I18n.t('ai.errors.api', message: e.message) }
  rescue JSON::ParserError => e
    Rails.logger.error "AI correction JSON parse error: #{e.message}"
    { score: nil, feedback: I18n.t('ai.errors.invalid_format') }
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

    @quiz_attempt.score            = score
    @quiz_attempt.results          = quiz_results_data
    @quiz_attempt.submitted_at     = Time.current
    @quiz_attempt.teacher_comments = {} if @quiz_attempt.persisted?

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
    Rails.logger.error "ERRO: #{e.class.name} - #{e.message}\n#{e.backtrace.join("\n")}"
    {
      success: false,
      redirect_path: Rails.application.routes.url_helpers.activities_path,
      alert: I18n.t('quiz.error')
    }
  end
end
