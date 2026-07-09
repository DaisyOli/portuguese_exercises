# Corrige com IA as respostas abertas pendentes de uma QuizAttempt.
# Roda dentro do AiGradingJob, fora do ciclo da requisição — o aluno vê o
# resultado das outras questões na hora e o feedback da IA chega em seguida.
require "anthropic"

class AiGradingService
  AI_CORRECTION_SYSTEM = <<~PROMPT
    Você é um avaliador de respostas de estudantes de português como segunda língua.
    Avalie a resposta do aluno de forma construtiva e encorajadora.
    Responda SOMENTE com JSON neste formato exato (sem markdown, sem texto extra):
    {"score": <inteiro de 0 a 100>, "feedback": "<feedback curto em português>"}
    Score 100 = resposta perfeita; 0 = em branco ou completamente errada.
  PROMPT

  PASSING_SCORE = 70

  def initialize(quiz_attempt)
    @attempt = quiz_attempt
  end

  # Corrige cada questão pendente salvando o progresso uma a uma: se o job
  # sofrer retry no meio, só as questões ainda pendentes são reenviadas à IA.
  def call
    return if pending_ids.empty?

    questions = @attempt.activity.questions.index_by(&:id)

    pending_ids.each do |key|
      entry    = @attempt.results["results"][key]
      question = questions[key.to_i]

      graded = if question.nil? || ENV["ANTHROPIC_API_KEY"].blank?
        { score: nil, feedback: I18n.t('ai.errors.generic') }
      else
        grade_question(question, entry["given_answer"])
      end

      apply_result!(key, graded)
    end

    recompute_totals!
  end

  # Usado quando os retries do job se esgotam: destrava a tela do aluno
  # com a mensagem de indisponibilidade em vez de "corrigindo..." eterno.
  def mark_pending_as_unavailable!(message)
    return if pending_ids.empty?

    pending_ids.each { |key| apply_result!(key, { score: nil, feedback: message }) }
    recompute_totals!
  end

  private

  def pending_ids
    results_hash.select { |_k, r| r.is_a?(Hash) && r["ai_pending"] }.keys
  end

  def results_hash
    data = @attempt.results
    data.is_a?(Hash) && data["results"].is_a?(Hash) ? data["results"] : {}
  end

  def grade_question(question, given_answer)
    client = Anthropic::Client.new(api_key: ENV.fetch("ANTHROPIC_API_KEY"))

    rubric_line = question.evaluation_prompt.present? \
      ? "Critérios de avaliação: #{question.evaluation_prompt}\n" \
      : ""

    message = client.messages.create(
      model: :"claude-haiku-4-5",
      max_tokens: 256,
      system: AI_CORRECTION_SYSTEM,
      messages: [{
        role: "user",
        content: "Questão: #{ActionView::Base.full_sanitizer.sanitize(question.content.to_s)}\n#{rubric_line}Resposta do aluno: #{given_answer.to_s.strip}"
      }]
    )

    text_block = message.content.find { |b| b.type == :text }
    parsed = JSON.parse(text_block.text.strip.gsub(/\A```(?:json)?\s*/i, '').gsub(/\s*```\z/, ''))
    { score: parsed["score"].to_i.clamp(0, 100), feedback: parsed["feedback"].to_s }

  rescue Anthropic::Errors::RateLimitError, Anthropic::Errors::APITimeoutError, Anthropic::Errors::APIConnectionError
    raise # temporários: deixa o AiGradingJob fazer retry com backoff
  rescue Anthropic::Errors::APIStatusError => e
    Rails.logger.error "AI grading API error: #{e.message}"
    { score: nil, feedback: I18n.t('ai.errors.api', message: e.message) }
  rescue JSON::ParserError => e
    Rails.logger.error "AI grading JSON parse error: #{e.message}"
    { score: nil, feedback: I18n.t('ai.errors.invalid_format') }
  end

  def apply_result!(key, graded)
    @attempt.results_will_change!
    entry = @attempt.results["results"][key]
    entry.delete("ai_pending")

    if graded[:score].nil?
      entry["is_correct"]     = nil
      entry["ai_score"]       = nil
      entry["ai_feedback"]    = graded[:feedback]
      entry["ai_unavailable"] = true
    else
      entry["is_correct"]  = graded[:score] >= PASSING_SCORE
      entry["ai_score"]    = graded[:score]
      entry["ai_feedback"] = graded[:feedback]
    end

    @attempt.save!
  end

  # Reaplica a mesma regra de pontuação do QuizSubmissionService: média
  # ponderada dos exercícios avaliados; pendentes e indisponíveis ficam fora.
  def recompute_totals!
    weights = @attempt.activity.questions.pluck(:id, :weight).to_h

    weighted_correct = 0.0
    weighted_possible = 0.0
    correct_count = 0
    exercise_count = 0

    results_hash.each do |key, entry|
      next if entry["ai_pending"] || entry["ai_unavailable"]

      weight = key.to_s.match?(/\A\d+\z/) ? (weights[key.to_i] || 1).to_f : 1.0
      weighted_possible += weight
      exercise_count    += 1
      if entry["is_correct"]
        weighted_correct += weight
        correct_count    += 1
      end
    end

    score = weighted_possible > 0 ? ((weighted_correct / weighted_possible) * 100).round(2) : 0

    @attempt.results_will_change!
    @attempt.results["score"]           = score
    @attempt.results["total_correct"]   = correct_count
    @attempt.results["total_questions"] = exercise_count
    @attempt.score = score
    @attempt.save!
  end
end
