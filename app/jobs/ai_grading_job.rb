# Corrige as respostas abertas de uma tentativa com IA, em background.
# Erros temporários da API sofrem retry com backoff; quando os retries se
# esgotam, as questões são marcadas como "correção indisponível" para a
# tela do aluno não ficar em "corrigindo..." para sempre.
class AiGradingJob < ApplicationJob
  queue_as :default

  retry_on Anthropic::Errors::RateLimitError, wait: :polynomially_longer, attempts: 5 do |job, _error|
    give_up(job, I18n.t('ai.errors.rate_limit'))
  end

  retry_on Anthropic::Errors::APITimeoutError, Anthropic::Errors::APIConnectionError,
           wait: :polynomially_longer, attempts: 3 do |job, _error|
    give_up(job, I18n.t('ai.errors.timeout'))
  end

  def perform(quiz_attempt_id)
    attempt = QuizAttempt.find_by(id: quiz_attempt_id)
    return unless attempt

    AiGradingService.new(attempt).call
  end

  def self.give_up(job, message)
    attempt = QuizAttempt.find_by(id: job.arguments.first)
    return unless attempt

    AiGradingService.new(attempt).mark_pending_as_unavailable!(message)
  end
end
