class ActivitiesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_activity, only: [:show, :edit, :update, :destroy, :resolve_quiz, :submit_quiz, :quiz_results]

  def index
    @activities = Activity.all
  end

  def show
    @questions = @activity.questions
    if current_user.role == "student"
      if session[:quiz_results].present? && session[:quiz_results][:activity_id] == @activity.id
        redirect_to quiz_results_activity_path(@activity)
      else
        redirect_to resolve_quiz_activity_path(@activity)
      end
    end
  end

  def resolve_quiz
    @questions = @activity.questions
  end

  def submit_quiz
    @activity = Activity.find(params[:id])
    @questions = @activity.questions
  
    # Processa os parâmetros para extrair as respostas
    answers = params[:answers] || {}
    
    Rails.logger.info "Respostas processadas: #{answers.inspect}"
    
    results = {}
    total_correct = 0
    
    @questions.each do |question|
      given_answer = answers[question.id.to_s]
      correct_answer = question.correct_answer
      
      is_correct = given_answer.present? && given_answer.to_s.strip == correct_answer.to_s.strip
      total_correct += 1 if is_correct
      
      results[question.id] = {
        question_text: question.content,
        given_answer: given_answer.presence || "Não respondida",
        correct_answer: correct_answer,
        is_correct: is_correct
      }
    end
    
    score = ((total_correct.to_f / @questions.count) * 100).round(2)
    
    @quiz_results = {
      activity_id: @activity.id,
      results: results,
      score: score,
      total_correct: total_correct,
      total_questions: @questions.count
    }
    
    # Salva os resultados na sessão
    session[:quiz_results] = @quiz_results
    
    Rails.logger.info "Resultados salvos na sessão: #{session[:quiz_results].inspect}"
    
    respond_to do |format|
      format.html { redirect_to quiz_results_activity_path(@activity) }
      format.turbo_stream { redirect_to quiz_results_activity_path(@activity) }
    end
  rescue => e
    Rails.logger.error "Erro ao processar quiz: #{e.message}"
    redirect_to resolve_quiz_activity_path(@activity), alert: 'Erro ao processar o quiz.'
  end

  def quiz_results
    @activity = Activity.find(params[:id])
    @quiz_results = session[:quiz_results]
    
    if @quiz_results.nil?
      redirect_to resolve_quiz_activity_path(@activity), alert: 'Por favor, responda o quiz primeiro.'
      return
    end
    
    render 'quiz_results'
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
    unless @activity.teacher == current_user
      redirect_to activities_path, alert: 'Você não tem permissão para editar esta atividade.'
    end
  end

  def update
    if @activity.teacher != current_user
      redirect_to activities_path, alert: 'Você não tem permissão para editar esta atividade.'
      return
    end

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
