class QuestionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_activity
  before_action :set_question, only: [:edit, :update, :destroy]
  before_action :check_teacher_permission

  def new
    @question = @activity.questions.build
  end

  def create
    @question = @activity.questions.build(question_params)
    
    Rails.logger.debug "============================================="
    Rails.logger.debug "CRIANDO NOVA QUESTÃO"
    Rails.logger.debug "Parâmetros recebidos: #{params.inspect}"
    Rails.logger.debug "Parâmetros permitidos: #{question_params.inspect}"
    Rails.logger.debug "Tipo de questão: #{@question.question_type}"
    
    if @question.question_type == 'order_sentences'
      Rails.logger.debug "QUESTÃO DE ORDENAÇÃO DE FRASES"
      Rails.logger.debug "Sentences content: #{@question.sentences_content.inspect}"
    elsif @question.question_type == 'multiple_choice'
      Rails.logger.debug "QUESTÃO DE MÚLTIPLA ESCOLHA"
      Rails.logger.debug "Options text: #{@question.options_text.inspect}"
    elsif @question.question_type == 'fill_in_blank'
      Rails.logger.debug "QUESTÃO DE PREENCHER LACUNAS"
      Rails.logger.debug "Content: #{@question.content.inspect}"
    end

    if @question.save
      Rails.logger.debug "QUESTÃO SALVA COM SUCESSO"
      Rails.logger.debug "ID: #{@question.id}"
      Rails.logger.debug "============================================="
      redirect_to activity_path(@activity, ultimo_id: @question.id), notice: t('messages.question_created')
    else
      Rails.logger.debug "ERRO AO SALVAR QUESTÃO"
      Rails.logger.debug "Erros de validação: #{@question.errors.full_messages}"
      Rails.logger.debug "============================================="
      
      flash.now[:alert] = "Erro ao criar questão: #{@question.errors.full_messages.join(', ')}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @question.update(question_params)
      redirect_to activity_path(@activity, ultimo_id: @question.id), notice: t('messages.question_updated')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @question.destroy
    redirect_to activity_path(@activity, ultima_acao: 'questao_excluida'), notice: t('messages.question_deleted')
  end

  private

  def set_activity
    @activity = Activity.find(params[:activity_id])
  end

  def set_question
    @question = @activity.questions.find(params[:id])
  end

  def question_params
    permitted = params.require(:question).permit(:content, :correct_answer, :question_type, :options_text, :sentences_content, options: [])
    Rails.logger.debug "Parâmetros permitidos em question_params: #{permitted.inspect}"
    permitted
  end

  def check_teacher_permission
    unless current_user.role == "teacher" && @activity.teacher == current_user
      redirect_to activities_path, alert: t('messages.permission_denied')
    end
  end
end

