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
  end
end
