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
          if given_answer.blank?
            # Sem resposta: nota 0 direto, não precisa de IA
            is_correct = false
            results[question.id] = {
              "is_correct"    => false,
              "question_text" => question.content,
              "question_type" => question.question_type,
              "given_answer"  => I18n.t('quiz.not_answered'),
              "ai_score"      => 0,
              "ai_feedback"   => I18n.t('quiz.not_answered')
            }
          else
            # A correção por IA roda em background (AiGradingJob) para não
            # segurar a requisição; fica fora do score até ser corrigida
            skip_score = true
            @has_pending_ai_grading = true
            results[question.id] = {
              "is_correct"    => nil,
              "question_text" => question.content,
              "question_type" => question.question_type,
              "given_answer"  => given_answer.to_s.strip,
              "ai_pending"    => true
            }
          end

        elsif question.fill_in_blank?
          all_answers = question.all_correct_answers
          given_raw   = @params.dig(:answers, question.id.to_s)
          given_array = if given_raw.respond_to?(:to_unsafe_h)
            given_raw.to_unsafe_h.sort_by { |k, _| k.to_i }.map { |_, v| v.to_s.strip }
          elsif given_raw.is_a?(Hash)
            given_raw.sort_by { |k, _| k.to_i }.map { |_, v| v.to_s.strip }
          else
            [given_raw.to_s.strip]
          end

          blank_results = all_answers.each_with_index.map do |correct, i|
            given     = given_array[i].to_s
            norm_g    = I18n.transliterate(given.downcase.gsub(/\s+/, ''))
            norm_c    = I18n.transliterate(correct.to_s.strip.downcase.gsub(/\s+/, ''))
            ok        = given.present? && norm_g == norm_c
            { "given" => given.presence || I18n.t('quiz.not_answered'), "correct" => correct, "ok" => ok }
          end

          is_correct = blank_results.all? { |r| r["ok"] }

          results[question.id] = {
            "is_correct"     => is_correct,
            "question_text"  => question.content,
            "question_type"  => question.question_type,
            "blank_results"  => blank_results,
            "given_answer"   => given_array.first.presence || I18n.t('quiz.not_answered'),
            "correct_answer" => all_answers.first,
            "raw_answer"     => given_array.first.to_s
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

    if (raw = @params[:started_at]).present?
      parsed = Time.zone.parse(raw) rescue nil
      if parsed && parsed < Time.current
        capped = [Time.current - parsed, 2.hours].min
        @quiz_attempt.started_at = Time.current - capped
      end
    end

    @quiz_attempt.score            = score
    @quiz_attempt.results          = quiz_results_data
    @quiz_attempt.submitted_at     = Time.current
    @quiz_attempt.teacher_comments = {} if @quiz_attempt.persisted?

    if @quiz_attempt.save
      AiGradingJob.perform_later(@quiz_attempt.id) if @has_pending_ai_grading
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
