class ActivitiesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_activity, only: [:show, :edit, :update, :destroy, :resolve_quiz, :submit_quiz]

  def index
    @activities = Activity.all
  end

  def show
    @activity = Activity.find(params[:id])
    @questions = @activity.questions
  end

  def resolve_quiz
    @questions = @activity.questions
  end

  def submit_quiz
    @activity = Activity.find(params[:id])
    answers = params[:answers] || {}
  
    @results = @activity.questions.map do |question|
      {
        question: question.content,
        given_answer: answers[question.id.to_s],
        correct_answer: question.correct_answer,
        correct: answers[question.id.to_s] == question.correct_answer
      }
    end
  
    render :quiz_results
  end

  def new
    @activity = current_user.activities.new
  end

  def create
    @activity = current_user.activities.new(activity_params)
    if @activity.save
      redirect_to new_activity_question_path(@activity), notice: "Activity created! Now add questions."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @activity.update(activity_params)
      redirect_to activity_path(@activity), notice: "Activity was successfully updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @activity.destroy
    redirect_to activities_path, notice: "Activity was successfully deleted"
  end
  
  private

  def set_activity
    @activity = Activity.find(params[:id])
  end

  def activity_params
    params.require(:activity).permit(:title, :description, :content_type, :content_url, :level)
  end
end
