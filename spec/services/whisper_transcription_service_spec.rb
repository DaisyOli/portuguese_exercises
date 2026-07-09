require 'rails_helper'

RSpec.describe WhisperTranscriptionService do
  let(:audio_file) { instance_double(ActionDispatch::Http::UploadedFile) }
  let(:client)     { instance_double(OpenAI::Client) }

  before do
    # Não depender da OPENAI_API_KEY real do ambiente (o CI não tem .env)
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return("chave-de-teste")
    allow(OpenAI::Client).to receive(:new).and_return(client)
    allow(client).to receive_message_chain(:audio, :transcribe)
      .and_return({ "text" => "Eu fui ao mercado ontem." })
  end

  describe "#call" do
    context "quando a transcrição funciona" do
      it "retorna success: true com o texto transcrito" do
        result = described_class.new(audio_file).call
        expect(result[:success]).to be true
        expect(result[:text]).to eq("Eu fui ao mercado ontem.")
      end
    end

    context "quando o Whisper retorna texto vazio" do
      before do
        allow(client).to receive_message_chain(:audio, :transcribe)
          .and_return({ "text" => "" })
      end

      it "retorna success: false com mensagem amigável" do
        result = described_class.new(audio_file).call
        expect(result[:success]).to be false
        expect(result[:error]).to be_present
      end
    end

    context "quando a API lança uma exceção" do
      before do
        allow(client).to receive_message_chain(:audio, :transcribe)
          .and_raise(StandardError, "connection error")
      end

      it "retorna success: false sem explodir" do
        result = described_class.new(audio_file).call
        expect(result[:success]).to be false
        expect(result[:error]).to be_present
      end
    end

    context "quando OPENAI_API_KEY não está configurada" do
      before { allow(ENV).to receive(:[]).and_call_original }
      before { allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return(nil) }

      it "retorna success: false sem chamar a API" do
        expect(OpenAI::Client).not_to receive(:new)
        result = described_class.new(audio_file).call
        expect(result[:success]).to be false
        expect(result[:error]).to be_present
      end
    end
  end
end
