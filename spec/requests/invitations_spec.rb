require 'rails_helper'

RSpec.describe "Invitations", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:admin)   { create(:user, :admin) }
  let(:teacher) { create(:user, :teacher) }
  let(:student) { create(:user, :student) }

  describe "GET /users/invitation/new" do
    context "como professora" do
      it "retorna 200" do
        sign_in teacher
        get new_user_invitation_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "como admin" do
      it "retorna 200" do
        sign_in admin
        get new_user_invitation_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "como aluno" do
      it "redireciona" do
        sign_in student
        get new_user_invitation_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "sem login" do
      it "redireciona para login" do
        get new_user_invitation_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /users/invitation — força role student para professoras" do
    let(:invite_email) { "aluno-novo@email.com" }

    context "professora tentando convidar" do
      it "cria convite com role student, mesmo se tentar enviar teacher" do
        sign_in teacher
        expect {
          post user_invitation_path, params: {
            user: { email: invite_email, role: "teacher", level: "A1" }
          }
        }.to change(User, :count).by(1)

        invited = User.find_by(email: invite_email)
        expect(invited.role).to eq("student")
      end
    end

    context "admin convidando professor" do
      it "permite criar convite com role teacher" do
        sign_in admin
        expect {
          post user_invitation_path, params: {
            user: { email: invite_email, role: "teacher" }
          }
        }.to change(User, :count).by(1)

        invited = User.find_by(email: invite_email)
        expect(invited.role).to eq("teacher")
      end
    end
  end
end
