require 'rails_helper'

RSpec.describe "Token CSRF inválido/expirado", type: :request do
  # allow_forgery_protection fica desligado no test.rb; ligamos só aqui pra
  # reproduzir de verdade o InvalidAuthenticityToken que o Rails levanta em produção.
  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  it "manda de volta pro login com aviso amigável em vez da página de erro padrão do Rails" do
    post user_session_path, params: { user: { email: "aluno@example.com", password: "senha123" } }

    expect(response).to redirect_to(new_user_session_path)
    expect(flash[:alert]).to eq(I18n.t("devise.failure.timeout"))
  end
end
