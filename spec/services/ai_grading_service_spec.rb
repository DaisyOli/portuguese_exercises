require 'rails_helper'

RSpec.describe AiGradingService do
  let(:teacher)  { create(:user, :teacher) }
  let(:student)  { create(:user, :student) }
  let(:activity) { create(:activity, teacher: teacher) }
  let!(:question_open) { create(:question, :open_ended, activity: activity) }

  let(:attempt) do
    create(:quiz_attempt, user: student, activity: activity, score: 100.0, results: {
      "activity_id" => activity.id,
      "results" => {
        "999999" => {
          "is_correct"    => true,
          "question_type" => "multiple_choice",
          "given_answer"  => "Brasília"
        },
        question_open.id.to_s => {
          "is_correct"    => nil,
          "question_type" => "open_ended",
          "given_answer"  => "Eu acordo às sete horas e tomo café.",
          "ai_pending"    => true
        }
      },
      "score" => 100.0,
      "total_correct" => 1,
      "total_questions" => 1
    })
  end

  let(:client) { instance_double(Anthropic::Client) }

  before do
    # Não depender da chave real do ambiente (o CI não tem .env)
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ANTHROPIC_API_KEY").and_return("chave-de-teste")
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("ANTHROPIC_API_KEY").and_return("chave-de-teste")
    allow(Anthropic::Client).to receive(:new).and_return(client)
  end

  def stub_ai_response(json)
    allow(client).to receive_message_chain(:messages, :create)
      .and_return(double(content: [double(type: :text, text: json)]))
  end

  describe '#call' do
    context 'quando a IA aprova a resposta' do
      before { stub_ai_response('{"score": 85, "feedback": "Muito bem, resposta clara!"}') }

      it 'preenche o feedback e recalcula o score com a questão incluída' do
        described_class.new(attempt).call
        attempt.reload

        entry = attempt.results["results"][question_open.id.to_s]
        expect(entry["ai_pending"]).to be_nil
        expect(entry["ai_score"]).to eq(85)
        expect(entry["ai_feedback"]).to eq("Muito bem, resposta clara!")
        expect(entry["is_correct"]).to be true

        expect(attempt.score).to eq(100.0)
        expect(attempt.results["total_questions"]).to eq(2)
        expect(attempt.results["total_correct"]).to eq(2)
        expect(attempt.ai_grading_pending?).to be false
      end
    end

    context 'quando a IA reprova a resposta' do
      before { stub_ai_response('{"score": 40, "feedback": "Faltaram detalhes."}') }

      it 'marca como incorreta e o score cai para a média ponderada' do
        described_class.new(attempt).call
        attempt.reload

        entry = attempt.results["results"][question_open.id.to_s]
        expect(entry["is_correct"]).to be false
        expect(attempt.score).to eq(50.0)
        expect(attempt.results["total_correct"]).to eq(1)
      end
    end

    context 'quando a API devolve erro temporário (rate limit)' do
      before do
        allow(client).to receive_message_chain(:messages, :create).and_raise(
          Anthropic::Errors::RateLimitError.new(url: URI("https://api.anthropic.com/v1/messages"),
                                                status: 429, headers: {}, body: nil, request: nil, response: nil)
        )
      end

      it 'deixa o erro subir para o job fazer retry, sem destravar o pendente' do
        expect { described_class.new(attempt).call }.to raise_error(Anthropic::Errors::RateLimitError)
        expect(attempt.reload.ai_grading_pending?).to be true
      end
    end

    context 'quando a API devolve erro permanente' do
      before do
        allow(client).to receive_message_chain(:messages, :create).and_raise(
          Anthropic::Errors::APIStatusError.new(url: URI("https://api.anthropic.com/v1/messages"),
                                                status: 500, headers: {}, body: nil, request: nil, response: nil)
        )
      end

      it 'marca como indisponível e tira a questão do cálculo' do
        described_class.new(attempt).call
        attempt.reload

        entry = attempt.results["results"][question_open.id.to_s]
        expect(entry["ai_unavailable"]).to be true
        expect(entry["ai_pending"]).to be_nil
        expect(attempt.score).to eq(100.0)
        expect(attempt.results["total_questions"]).to eq(1)
      end
    end

    context 'sem ANTHROPIC_API_KEY configurada' do
      before do
        allow(ENV).to receive(:[]).with("ANTHROPIC_API_KEY").and_return(nil)
      end

      it 'marca como indisponível sem chamar a API' do
        expect(Anthropic::Client).not_to receive(:new)
        described_class.new(attempt).call

        entry = attempt.reload.results["results"][question_open.id.to_s]
        expect(entry["ai_unavailable"]).to be true
      end
    end
  end

  describe '#mark_pending_as_unavailable!' do
    it 'destrava as pendências com a mensagem recebida' do
      described_class.new(attempt).mark_pending_as_unavailable!("IA fora do ar")
      attempt.reload

      entry = attempt.results["results"][question_open.id.to_s]
      expect(entry["ai_unavailable"]).to be true
      expect(entry["ai_feedback"]).to eq("IA fora do ar")
      expect(attempt.ai_grading_pending?).to be false
    end
  end
end
