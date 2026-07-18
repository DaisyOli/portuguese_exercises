module Api
  module V1
    class BaseController < ActionController::API
      before_action :verify_trial_api_key!

      private

      # A chave só é exigida quando TRIAL_API_KEY está configurada no ambiente
      # (em produção ela deve estar sempre configurada; sem ela o endpoint fica aberto).
      def verify_trial_api_key!
        expected = ENV["TRIAL_API_KEY"]
        return if expected.blank?

        provided = request.headers["X-Trial-Api-Key"].to_s
        return if ActiveSupport::SecurityUtils.secure_compare(provided, expected)

        render_error(:unauthorized, "Chave de API inválida.")
      end

      def render_error(status, message)
        render json: { ok: false, error: message }, status: status
      end
    end
  end
end
