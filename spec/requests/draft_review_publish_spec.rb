require 'rails_helper'

# Auditoria do fluxo de aprovação: rascunho gerado (por prompt, vídeo ou
# agente) → revisar → publicar, respeitando dona, outras professoras e admin.
RSpec.describe "Revisão e publicação de rascunhos", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:owner)         { create(:user, :teacher) }
  let(:other_teacher) { create(:user, :teacher) }
  let(:admin)         { create(:user, :admin) }
  let!(:draft) do
    create(:activity, teacher: owner, draft: true, ai_generated: true,
                      title: "Rascunho da IA", description: "desc", level: "A1")
  end

  describe "dona do rascunho" do
    before { sign_in owner }

    it "revisa e publica" do
      get review_draft_activity_path(draft)
      expect(response).to have_http_status(:ok)

      post publish_draft_activity_path(draft)
      expect(response).to redirect_to(activity_path(draft))
      expect(draft.reload.draft).to be(false)
      expect(draft.published_at).to be_present
    end

    it "vê o botão Revisar na lista" do
      get activities_path
      expect(response.body).to include(review_draft_activity_path(draft))
    end

    it "publicar de novo não quebra (idempotente)" do
      post publish_draft_activity_path(draft)
      post publish_draft_activity_path(draft)
      expect(draft.reload.draft).to be(false)
    end
  end

  describe "outra professora" do
    before { sign_in other_teacher }

    it "não vê o rascunho alheio na lista de atividades" do
      get activities_path
      expect(response.body).not_to include("Rascunho da IA")
    end

    it "não revisa nem edita nem publica rascunho alheio" do
      get review_draft_activity_path(draft)
      expect(response).to redirect_to(activities_path)

      get edit_activity_path(draft)
      expect(response).to redirect_to(activities_path)

      post publish_draft_activity_path(draft)
      expect(response).to redirect_to(activities_path)
      expect(draft.reload.draft).to be(true)
    end

    it "vê atividades publicadas de outras professoras (sem Editar)" do
      published = create(:activity, teacher: owner, draft: false,
                                    title: "Publicada da colega", description: "d", level: "A1")
      get activities_path
      expect(response.body).to include("Publicada da colega")
      expect(response.body).not_to include(edit_activity_path(published))
    end
  end

  describe "admin (agente de conteúdo)" do
    before { sign_in admin }

    it "revisa e publica rascunho de IA de outra professora" do
      get review_draft_activity_path(draft)
      expect(response).to have_http_status(:ok)

      post publish_draft_activity_path(draft)
      expect(response).to redirect_to(activity_path(draft))
      expect(draft.reload.draft).to be(false)
    end

    it "acompanha a espera de uma geração do agente" do
      generation = AiGeneration.create!(teacher: owner, kind: "agent",
                                        request_params: { level: "A1" })
      get generation_wait_activities_path(id: generation.id)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t('ai_generation.wait_title'))
    end
  end
end
