require 'rails_helper'

RSpec.describe "POST /activities/:slug/clear/:content", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:teacher)  { create(:user, :teacher) }
  let(:activity) { create(:activity, teacher: teacher, statement: "Texto do enunciado", media_url: "https://exemplo.com/img.png") }

  it "professora dona limpa o conteúdo indicado" do
    sign_in teacher
    post clear_content_activity_path(activity, content: "statement")

    expect(activity.reload.statement).to be_nil
    expect(activity.media_url).to be_present
    expect(response).to redirect_to(activity_path(activity, ultima_acao: 'conteudo_excluido'))
  end

  it "outra professora não pode limpar" do
    sign_in create(:user, :teacher)
    post clear_content_activity_path(activity, content: "statement")

    expect(activity.reload.statement).to eq("Texto do enunciado")
    expect(response).to redirect_to(activities_path)
  end

  it "conteúdo fora da whitelist nem roteia (404)" do
    sign_in teacher
    post "/activities/#{activity.slug}/clear/teacher_id"

    expect(response).to have_http_status(:not_found)
    expect(activity.reload.teacher_id).to eq(teacher.id)
  end
end
