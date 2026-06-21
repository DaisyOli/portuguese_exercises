require 'rails_helper'

RSpec.describe "Admin::Dashboard", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:admin)   { create(:user, :admin) }
  let(:teacher) { create(:user, :teacher) }
  let(:student) { create(:user, :student) }

  describe "GET /admin" do
    context "como admin" do
      it "retorna 200" do
        sign_in admin
        get admin_root_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "como professora sem admin" do
      it "redireciona com alerta de acesso restrito" do
        sign_in teacher
        get admin_root_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "como aluno" do
      it "redireciona" do
        sign_in student
        get admin_root_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "sem login" do
      it "redireciona para login" do
        get admin_root_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
