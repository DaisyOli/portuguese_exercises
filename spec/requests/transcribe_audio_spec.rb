require 'rails_helper'

RSpec.describe "POST /activities/:slug/transcribe", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:teacher)  { create(:user, :teacher) }
  let(:student)  { create(:user, :student) }
  let(:activity) { create(:activity, teacher: teacher) }
  let(:audio_file) do
    Rack::Test::UploadedFile.new(
      StringIO.new("fake audio data"),
      "audio/webm",
      original_filename: "recording.webm"
    )
  end

  describe "autenticação" do
    it "redireciona usuário não autenticado" do
      post transcribe_activity_path(activity)
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "como aluno autenticado" do
    before { sign_in student }

    context "sem áudio no request" do
      it "retorna 422 com mensagem de erro" do
        post transcribe_activity_path(activity), as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to be_present
      end
    end

    context "com áudio e serviço retornando sucesso" do
      before do
        allow(WhisperTranscriptionService).to receive(:new)
          .and_return(double(call: { success: true, text: "Eu moro em Paris." }))
      end

      it "retorna 200 com o texto transcrito" do
        post transcribe_activity_path(activity), params: { audio: audio_file }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["text"]).to eq("Eu moro em Paris.")
      end
    end

    context "com áudio e serviço retornando erro" do
      before do
        allow(WhisperTranscriptionService).to receive(:new)
          .and_return(double(call: { success: false, error: "Não entendi o áudio." }))
      end

      it "retorna 422 com a mensagem de erro do serviço" do
        post transcribe_activity_path(activity), params: { audio: audio_file }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to eq("Não entendi o áudio.")
      end
    end
  end

  describe "como professora autenticada" do
    before do
      sign_in teacher
      allow(WhisperTranscriptionService).to receive(:new)
        .and_return(double(call: { success: true, text: "Texto transcrito." }))
    end

    it "também pode transcrever (para testar as próprias atividades)" do
      post transcribe_activity_path(activity), params: { audio: audio_file }
      expect(response).to have_http_status(:ok)
    end
  end
end
