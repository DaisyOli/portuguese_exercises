require 'rails_helper'

RSpec.describe "GET /activities/:slug/grading_status", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:teacher)  { create(:user, :teacher) }
  let(:student)  { create(:user, :student) }
  let(:activity) { create(:activity, teacher: teacher) }

  before { sign_in student }

  it "responde pending: true enquanto há correção por IA em andamento" do
    attempt = create(:quiz_attempt, user: student, activity: activity)
    results = attempt.results
    results["results"]["77"] = { "question_type" => "open_ended", "ai_pending" => true }
    attempt.update!(results: results)

    get grading_status_activity_path(activity)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq("pending" => true)
  end

  it "responde pending: false quando não há nada pendente" do
    create(:quiz_attempt, user: student, activity: activity)

    get grading_status_activity_path(activity)

    expect(response.parsed_body).to eq("pending" => false)
  end

  it "responde pending: false sem nenhuma tentativa" do
    get grading_status_activity_path(activity)

    expect(response.parsed_body).to eq("pending" => false)
  end
end
