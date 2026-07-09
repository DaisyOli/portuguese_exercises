require 'rails_helper'

RSpec.describe "GET /activities/:slug como aluno", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:teacher)  { create(:user, :teacher) }
  let(:student)  { create(:user, :student) }
  let(:activity) { create(:activity, teacher: teacher) }

  before { sign_in student }

  # Regressão: usava o helper inexistente resolve_quiz_activity_path e dava 500
  it "redireciona o aluno para a página de resolver o quiz" do
    get activity_path(activity)
    expect(response).to redirect_to(solve_activity_path(activity))
  end
end
