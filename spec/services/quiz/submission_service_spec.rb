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
        answers_order: {},
        answers_sentences: {}
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