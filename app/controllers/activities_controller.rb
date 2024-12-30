class ActivitiesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_activity, only: [:show, :edit, :update, :destroy, :resolve_quiz, :submit_quiz]

  def index
    @activities = Activity.all
  end

  def show
    @activity = Activity.find(params[:id])
    @questions = @activity.questions
    if current_user.role == "student"
      redirect_to resolve_quiz_activity_path(@activity)
    end 
  end

  def resolve_quiz
    @questions = @activity.questions
  end

  def submit_quiz
    @activity = Activity.find(params[:id])
    answers = params[:answers] || {}
    Rails.logger.debug "Received answers: #{answers.inspect}"
  
    # Calcular os resultados do quiz
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
  
    # Armazenar resultados temporariamente na sessão
    session[:quiz_results] = @results
  
    # Redirecionar para a página de resultados
    redirect_to quiz_results_activity_path(@activity)
  end
  
  
  def quiz_results
    @activity = Activity.find(params[:id])
    @results = session.delete(:quiz_results) || [] # Certifique-se de que a sessão não está vazia
    Rails.logger.debug "Quiz Results: #{@results.inspect}"
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
