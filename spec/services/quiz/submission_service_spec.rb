require 'rails_helper'

RSpec.describe QuizSubmissionService, type: :service do
  let(:activity) { create(:activity) }
  let(:user) { create(:user, :student) }
  let(:question_fill) { create(:question, :fill_in_blank, activity: activity, content: "O gato _____ no telhado.", correct_answer: "está") }
  let(:question_mc) { create(:question, :multiple_choice, activity: activity, content: "Qual é a capital do Brasil?", correct_answer: "Brasília", options: ["São Paulo", "Brasília", "Rio de Janeiro"]) }
  
  let(:params) do
    {
      answers: {
        question_fill.id.to_s => "está",
        question_mc.id.to_s => "Brasília"
      }
    }
  end
  
  let(:session) { {} }
  
  subject(:service) do
    QuizSubmissionService.new(
      activity: activity,
      user: user,
      params: params,
      session: session
    )
  end

  describe '#call' do
    context 'com respostas corretas' do
      it 'processa o quiz corretamente' do
        result = service.call
        
        expect(result[:success]).to be true
        expect(result[:quiz_attempt]).to be_a(QuizAttempt)
        expect(result[:quiz_attempt].score).to eq(100.0)
        expect(result[:show_score]).to be true
        expect(result[:score]).to eq(100.0)
      end

      it 'salva os resultados corretamente no banco' do
        result = service.call
        quiz_attempt = result[:quiz_attempt]
        
        expect(quiz_attempt.persisted?).to be true
        expect(quiz_attempt.results["total_correct"]).to eq(2)
        expect(quiz_attempt.results["total_questions"]).to eq(2)
        expect(quiz_attempt.results["score"]).to eq(100.0)
      end

      it 'atualiza a sessão corretamente' do
        result = service.call
        
        expect(session[:quiz_attempt_id]).to eq(result[:quiz_attempt].id)
        expect(session[:last_quiz_score]).to eq(100.0)
        expect(session[:completed_quizzes]).to include(activity.id)
      end

      it 'redireciona para resolve_quiz com parâmetro show_score' do
        result = service.call

        expect(result[:redirect_path]).to include("show_score=true")
        expect(result[:show_score]).to be true
        expect(result[:notice]).to be_nil
      end
    end

    context 'com respostas incorretas' do
      let(:params) do
        {
          answers: {
            question_fill.id.to_s => "era",
            question_mc.id.to_s => "São Paulo"
          }
        }
      end

      it 'processa respostas incorretas' do
        result = service.call
        
        expect(result[:success]).to be true
        expect(result[:quiz_attempt].score).to eq(0.0)
        expect(result[:show_score]).to be true
      end
    end

    context 'com questão fill_in_blank' do
      let(:params) do
        {
          answers: {
            question_fill.id.to_s => "  ESTÁ  "  # com espaços e maiúsculas
          }
        }
      end

      it 'normaliza a resposta corretamente' do
        result = service.call
        
        # Deve aceitar a resposta mesmo com espaços e maiúsculas diferentes
        question_result = result[:quiz_attempt].results["results"][question_fill.id.to_s]
        expect(question_result["is_correct"]).to be true
      end
    end

    context 'com respostas em branco' do
      let(:params) do
        {
          answers: {
            question_fill.id.to_s => "",
            question_mc.id.to_s => ""
          }
        }
      end

      it 'trata respostas em branco' do
        result = service.call
        
        expect(result[:quiz_attempt].score).to eq(0.0)
        
        question_result = result[:quiz_attempt].results["results"][question_fill.id.to_s]
        expect(question_result["given_answer"]).to eq(I18n.t('quiz.not_answered'))
      end
    end

    context 'com questão de resposta aberta (correção por IA em background)' do
      let(:question_open) { create(:question, :open_ended, activity: activity) }
      let(:params) do
        {
          answers: {
            question_open.id.to_s => "Eu acordo às sete horas todos os dias.",
            question_mc.id.to_s   => "Brasília"
          }
        }
      end

      it 'marca a resposta como pendente e enfileira o AiGradingJob' do
        result = nil
        expect { result = service.call }.to have_enqueued_job(AiGradingJob)

        attempt = result[:quiz_attempt]
        entry = attempt.results["results"][question_open.id.to_s]
        expect(entry["ai_pending"]).to be true
        expect(entry["is_correct"]).to be_nil
        expect(attempt.ai_grading_pending?).to be true
      end

      it 'calcula o score inicial só com as questões já corrigidas' do
        result = service.call
        attempt = result[:quiz_attempt]

        expect(attempt.score).to eq(100.0)
        expect(attempt.results["total_questions"]).to eq(1)
      end

      it 'resposta aberta em branco ganha 0 direto, sem IA e sem job' do
        params[:answers][question_open.id.to_s] = ""

        result = nil
        expect { result = service.call }.not_to have_enqueued_job(AiGradingJob)

        attempt = result[:quiz_attempt]
        entry = attempt.results["results"][question_open.id.to_s]
        expect(entry["ai_pending"]).to be_nil
        expect(entry["is_correct"]).to be false
        expect(entry["ai_score"]).to eq(0)
        expect(attempt.results["total_questions"]).to eq(2)
      end
    end

    context 'para usuário não autenticado' do
      let(:user) { nil }

      it 'cria tentativa sem usuário' do
        result = service.call
        
        expect(result[:success]).to be true
        expect(result[:quiz_attempt].user).to be_nil
        expect(result[:quiz_attempt].activity).to eq(activity)
      end
    end

    context 'quando ocorre erro' do
      before do
        allow(activity).to receive(:questions).and_raise(StandardError.new("Erro de teste"))
      end

      it 'trata erros graciosamente' do
        result = service.call

        expect(result[:success]).to be false
        expect(result[:alert]).to be_present
        expect(result[:redirect_path]).to include("activities")
      end
    end

    context 'com questão fill_in_blank de múltiplas lacunas parcialmente correta' do
      let(:question_multi_blank) do
        create(:question,
          activity: activity,
          question_type: 'fill_in_blank',
          content: "O _____ correu pelo _____ e comeu uma _____ perto do _____.",
          correct_answer: "gato",
          correct_answers: ["gato", "parque", "maçã", "lago"])
      end

      let(:params) do
        {
          answers: {
            question_multi_blank.id.to_s => {
              "0" => "gato",   # certo
              "1" => "parque", # certo
              "2" => "pera",   # errado
              "3" => "lago"    # certo
            }
          }
        }
      end

      it 'dá crédito parcial na nota em vez de zerar a questão' do
        result = service.call
        attempt = result[:quiz_attempt]

        # 3 de 4 lacunas certas = 75% de crédito, única questão no quiz
        expect(attempt.score).to eq(75.0)
      end

      it 'mantém is_correct false mas guarda o detalhe por lacuna' do
        result = service.call
        attempt = result[:quiz_attempt]

        q_result = attempt.results["results"][question_multi_blank.id.to_s]
        expect(q_result["is_correct"]).to be false
        expect(q_result["correct_count"]).to eq(3)
        expect(q_result["total_blanks"]).to eq(4)
        expect(q_result["blank_results"].count { |r| r["ok"] }).to eq(3)
      end
    end

    context 'com exercício de associar colunas parcialmente correto' do
      let(:column_matching) { activity.column_matchings.create!(title: "Capitais") }
      let!(:cm_pair1) { column_matching.add_pair("Brasil", "Brasília") }
      let!(:cm_pair2) { column_matching.add_pair("França", "Paris") }
      let!(:cm_pair3) { column_matching.add_pair("Japão", "Tóquio") }
      let!(:cm_pair4) { column_matching.add_pair("Egito", "Cairo") }

      let(:params) do
        {
          answers: {
            question_fill.id.to_s => "está",
            question_mc.id.to_s => "Brasília"
          },
          column_matching_answers: {
            column_matching.id.to_s => [
              "#{cm_pair1.id}:#{cm_pair1.id}",
              "#{cm_pair2.id}:#{cm_pair2.id}",
              "#{cm_pair3.id}:#{cm_pair3.id}",
              "#{cm_pair4.id}:#{cm_pair1.id}" # errou este par
            ].join(',')
          }
        }
      end

      it 'dá crédito parcial na nota final em vez de zerar o exercício' do
        result = service.call
        attempt = result[:quiz_attempt]

        # 2 questões (100%) + column matching (3/4 = 75%) sobre 3 exercícios no total
        expect(attempt.score).to eq(((2 + 0.75) / 3 * 100).round(2))
      end

      it 'guarda o detalhe por par no resultado, sem zerar os pares certos' do
        result = service.call
        attempt = result[:quiz_attempt]

        cm_result = attempt.results["results"]["column_matching_#{column_matching.id}"]
        expect(cm_result["is_correct"]).to be false
        expect(cm_result["correct_count"]).to eq(3)
        expect(cm_result["total_pairs"]).to eq(4)
        expect(cm_result["pair_results"].count { |r| r["correct"] }).to eq(3)
      end
    end

    context 'atualização de tentativa existente' do
      let!(:existing_attempt) { create(:quiz_attempt, user: user, activity: activity, score: 50.0) }

      it 'atualiza tentativa existente em vez de criar nova' do
        expect {
          service.call
        }.not_to change(QuizAttempt, :count)
        
        existing_attempt.reload
        expect(existing_attempt.score).to eq(100.0)
      end
    end
  end

  describe 'integração com lógica original' do
    it 'mantém compatibilidade com controller atual' do
      # Simular os mesmos parâmetros que vêm do controller
      controller_params = {
        id: activity.id,
        answers: {
          question_fill.id.to_s => "está",
          question_mc.id.to_s => "Brasília"
        },
        answers_raw: {},
        answers_alt: {},
        answers_order: {}
      }
      
      service = QuizSubmissionService.new(
        activity: activity,
        user: user,
        params: controller_params,
        session: session
      )
      
      result = service.call
      
      expect(result[:success]).to be true
      expect(result[:quiz_attempt].score).to eq(100.0)
    end
  end
end 