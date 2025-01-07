class ActivitiesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_activity, only: [:show, :edit, :update, :destroy, :resolve_quiz, :submit_quiz, :quiz_results]

  def index
    @activities = current_user.teacher? ? current_user.activities : Activity.all
  end

  def show
    @questions = @activity.questions
    if current_user.role == "student"
      redirect_to resolve_quiz_activity_path(@activity)
    end
  end

  def resolve_quiz
    @questions = @activity.questions
  end

  def submit_quiz
    answers = params[:answers] || {}
    Rails.logger.debug "Received answers: #{answers.inspect}"

    @results = @activity.questions.map do |question|
      given_answer = answers[question.id.to_s]
      correct = given_answer&.strip == question.correct_answer.strip
      {
        question: question.content,
        given_answer: given_answer,
        correct_answer: question.correct_answer,
        correct: correct
      }
    end

    Rails.logger.debug "Results: #{@results.inspect}"
    session[:quiz_results] = @results
    redirect_to quiz_results_activity_path(@activity)
  end

  def quiz_results
    @results = session.delete(:quiz_results) || []
    Rails.logger.debug "Quiz Results: #{@results.inspect}"
  end

  def new
    @activity = Activity.new
  end

  def create
    @activity = Activity.new(activity_params)
    @activity.teacher = current_user

    if @activity.save
      redirect_to new_activity_question_path(@activity), notice: "Atividade criada! Agora adicione as questões."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @activity.update(activity_params)
      redirect_to @activity, notice: 'Atividade atualizada com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @activity.destroy
    redirect_to activities_url, notice: 'Atividade excluída com sucesso.'
  end

  private

  def set_activity
    @activity = Activity.find(params[:id])
  end

  def activity_params
    params.require(:activity).permit(:title, :description, :level)
  end
end
