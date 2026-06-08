class QuestionsController < ApplicationController
  before_action :set_activity
  before_action :set_question, only: [:edit, :update, :destroy]
  before_action :check_teacher_permission

  def new
    @question = @activity.questions.build
  end

  def create
    @question = @activity.questions.new(question_params)

    if @question.save
      redirect_to activity_path(@activity, ultimo_id: @question.id), notice: t('messages.question_created')
    else
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
    @activity = Activity.find_by!(slug: params[:activity_slug])
  end

  def set_question
    @question = @activity.questions.find(params[:id])
  end

  def question_params
    params.require(:question).permit(:content, :correct_answer, :question_type, :options_text, :evaluation_prompt, :weight, options: [])
  end

  def check_teacher_permission
    unless current_user.teacher? && @activity.teacher == current_user
      redirect_to activities_path, alert: t('messages.permission_denied') and return
    end
  end
end

