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
    
    Rails.logger.debug "Parâmetros recebidos: #{params.inspect}"
    Rails.logger.debug "Parâmetros permitidos: #{question_params.inspect}"
    Rails.logger.debug "Questão construída: #{@question.inspect}"
    Rails.logger.debug "Opções: #{@question.options.inspect}"
    Rails.logger.debug "Options text: #{@question.options_text.inspect}"
    Rails.logger.debug "Sentences content: #{@question.sentences_content.inspect}"

    if @question.save
      redirect_to activity_path(@activity, ultimo_id: @question.id), notice: t('messages.question_created')
    else
      Rails.logger.debug "Erros de validação: #{@question.errors.full_messages}"
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
    permitted = params.require(:question).permit(:content, :correct_answer, :question_type, :points, :options_text, :sentences_content, options: [])
    Rails.logger.debug "Parâmetros permitidos em question_params: #{permitted.inspect}"
    permitted
  end

  def check_teacher_permission
    unless current_user.role == "teacher" && @activity.teacher == current_user
      redirect_to activities_path, alert: t('messages.permission_denied')
    end
  end
end

