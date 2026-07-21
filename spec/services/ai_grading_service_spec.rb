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

      it 'preenche o feedback e usa o ai_score como fração de crédito no score final' do
        described_class.new(attempt).call
        attempt.reload

        entry = attempt.results["results"][question_open.id.to_s]
        expect(entry["ai_pending"]).to be_nil
        expect(entry["ai_score"]).to eq(85)
        expect(entry["ai_feedback"]).to eq("Muito bem, resposta clara!")
        expect(entry["is_correct"]).to be true
        expect(entry["credit_fraction"]).to eq(0.85)

        # multiple_choice (100%) + open_ended (85%) sobre 2 questões = 92.5
        expect(attempt.score).to eq(92.5)
        expect(attempt.results["total_questions"]).to eq(2)
        expect(attempt.results["total_correct"]).to eq(2)
        expect(attempt.ai_grading_pending?).to be false
      end
    end

    context 'quando a IA reprova a resposta' do
      before { stub_ai_response('{"score": 40, "feedback": "Faltaram detalhes."}') }

      it 'marca como incorreta mas ainda dá crédito parcial proporcional ao ai_score' do
        described_class.new(attempt).call
        attempt.reload

        entry = attempt.results["results"][question_open.id.to_s]
        expect(entry["is_correct"]).to be false
        expect(entry["credit_fraction"]).to eq(0.4)

        # multiple_choice (100%) + open_ended (40%) sobre 2 questões = 70.0 — não zera a questão
        expect(attempt.score).to eq(70.0)
        expect(attempt.results["total_correct"]).to eq(1)
      end
    end

    context 'quando a IA dá uma nota abaixo da aprovação mas ainda alta' do
      before { stub_ai_response('{"score": 65, "feedback": "Quase lá, só um detalhe."}') }

      it 'não zera a questão só porque ficou abaixo do corte de aprovação' do
        described_class.new(attempt).call
        attempt.reload

        entry = attempt.results["results"][question_open.id.to_s]
        expect(entry["is_correct"]).to be false # abaixo de 70, não passou

        # multiple_choice (100%) + open_ended (65%) sobre 2 questões = 82.5,
        # bem diferente do 50.0 que o corte binário antigo teria dado
        expect(attempt.score).to eq(82.5)
      end
    end

    context 'quando o quiz também tem exercícios com crédito parcial já calculado' do
      let(:attempt) do
        create(:quiz_attempt, user: student, activity: activity, score: 87.5, results: {
          "activity_id" => activity.id,
          "results" => {
            "888888" => {
              "is_correct"      => false,
              "question_type"   => "fill_in_blank",
              "correct_count"   => 3,
              "total_blanks"    => 4,
              "credit_fraction" => 0.75
            },
            question_open.id.to_s => {
              "is_correct"    => nil,
              "question_type" => "open_ended",
              "given_answer"  => "Eu acordo às sete horas e tomo café.",
              "ai_pending"    => true
            }
          },
          "score" => 87.5,
          "total_correct" => 0,
          "total_questions" => 1
        })
      end

      before { stub_ai_response('{"score": 100, "feedback": "Perfeito!"}') }

      it 'preserva o crédito parcial do outro exercício em vez de zerá-lo no recálculo' do
        described_class.new(attempt).call
        attempt.reload

        fib_entry = attempt.results["results"]["888888"]
        expect(fib_entry["credit_fraction"]).to eq(0.75) # não foi sobrescrito

        # fill_in_blank (75%) + open_ended (100%) sobre 2 exercícios = 87.5
        expect(attempt.score).to eq(87.5)
        expect(attempt.results["total_correct"]).to eq(1) # só o open_ended é is_correct
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
