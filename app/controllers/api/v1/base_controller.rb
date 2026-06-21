module Api
  module V1
    class BaseController < ActionController::API
      private

      def render_error(status, message)
        render json: { ok: false, error: message }, status: status
      end
    end
  end
end
