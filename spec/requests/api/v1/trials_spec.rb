require 'rails_helper'

RSpec.describe "Api::V1::Trials", type: :request do
  let(:valid_params) { { email: "novo@email.com", level: "B1" } }

  describe "POST /api/v1/trials" do
    context "com dados válidos" do
      it "cria um usuário trial e retorna 200" do
        expect {
          post "/api/v1/trials", params: valid_params, as: :json
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)["ok"]).to be true
      end

      it "cria o usuário com role trial e level correto" do
        post "/api/v1/trials", params: valid_params, as: :json

        user = User.find_by(email: "novo@email.com")
        expect(user).to be_present
        expect(user.role).to eq("trial")
        expect(user.level).to eq("B1")
      end

      it "define trial_expires_at 7 dias no futuro" do
        post "/api/v1/trials", params: valid_params, as: :json

        user = User.find_by(email: "novo@email.com")
        expect(user.trial_expires_at).to be_within(1.minute).of(7.days.from_now)
      end
    end

    context "com email já existente" do
      before { create(:user, email: "novo@email.com") }

      it "retorna 422 e não cria usuário duplicado" do
        expect {
          post "/api/v1/trials", params: valid_params, as: :json
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "com email inválido" do
      it "retorna 422" do
        post "/api/v1/trials", params: { email: "nao-é-email", level: "B1" }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "sem email" do
      it "retorna 422" do
        post "/api/v1/trials", params: { level: "B1" }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "com nível inválido" do
      it "retorna 422" do
        post "/api/v1/trials", params: { email: "novo@email.com", level: "Z9" }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "sem nível" do
      it "retorna 422" do
        post "/api/v1/trials", params: { email: "novo@email.com" }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "com TRIAL_API_KEY configurada" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("TRIAL_API_KEY").and_return("chave-secreta")
      end

      it "retorna 401 sem o header X-Trial-Api-Key" do
        expect {
          post "/api/v1/trials", params: valid_params, as: :json
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unauthorized)
      end

      it "retorna 401 com chave errada" do
        post "/api/v1/trials", params: valid_params, as: :json, headers: { "X-Trial-Api-Key" => "chave-errada" }
        expect(response).to have_http_status(:unauthorized)
      end

      it "cria o usuário com a chave correta" do
        expect {
          post "/api/v1/trials", params: valid_params, as: :json, headers: { "X-Trial-Api-Key" => "chave-secreta" }
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end

    context "rate limiting por email" do
      before do
        Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
      end

      after do
        Rack::Attack.cache.store = Rails.cache
      end

      it "retorna 429 depois de 3 tentativas com o mesmo email" do
        3.times { post "/api/v1/trials", params: valid_params, as: :json }

        post "/api/v1/trials", params: valid_params, as: :json
        expect(response).to have_http_status(:too_many_requests)
      end

      it "não bloqueia emails diferentes vindos do mesmo IP" do
        3.times { post "/api/v1/trials", params: valid_params, as: :json }

        post "/api/v1/trials", params: { email: "outro@email.com", level: "A2" }, as: :json
        expect(response).to have_http_status(:created)
      end
    end
  end
end
