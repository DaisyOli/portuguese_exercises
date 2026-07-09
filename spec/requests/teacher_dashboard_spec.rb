require 'rails_helper'

RSpec.describe "GET /teacher_dashboard", type: :request do
  include Devise::Test::IntegrationHelpers

  describe "professor sem nenhuma atividade" do
    let(:teacher) { create(:user, :teacher) }

    before { sign_in teacher }

    # Regressão: bar_max ficava 0 e (n / 0.0).round explodia com FloatDomainError (NaN)
    it "renderiza a dashboard sem erro" do
      get teacher_dashboard_path
      expect(response).to have_http_status(:ok)
    end
  end
end
