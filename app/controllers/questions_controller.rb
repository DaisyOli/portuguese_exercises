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
    process_options

    if @question.save
      redirect_to activity_path(@activity), notice: t('messages.question_created')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @question.update(question_params)
      process_options
      if @question.save
        redirect_to activity_path(@activity), notice: t('messages.question_updated')
      else
        render :edit, status: :unprocessable_entity
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @question.destroy
    redirect_to activity_path(@activity), notice: t('messages.question_deleted')
  end

  private

  def set_activity
    @activity = Activity.find(params[:activity_id])
  end

  def set_question
    @question = @activity.questions.find(params[:id])
  end

  def question_params
    params.require(:question).permit(:content, :correct_answer, :options)
  end

  def process_options
    if params[:question][:options].present?
      @question.options = params[:question][:options].split(",").map(&:strip)
    end
  end

  def check_teacher_permission
    unless current_user.role == "teacher" && @activity.teacher == current_user
      redirect_to activities_path, alert: t('messages.permission_denied')
    end
  end
end

