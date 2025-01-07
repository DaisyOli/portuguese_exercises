class QuestionsController < ApplicationController
  def new
    @activity = Activity.find(params[:activity_id])
    @question = @activity.questions.build
  end

  def create
  @activity = Activity.find(params[:activity_id])
  @question = @activity.questions.build(question_params)

  if params[:question][:options].present?
    @question.options = params[:question][:options].split(",").map(&:strip)
  end

  if @question.save
    respond_to do |format|
      format.html { redirect_to activity_path(@activity), notice: "Question added successfully!" }
  
    end
  else
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("question_form", partial: "questions/form", locals: { question: @question, activity: @activity }) }
      format.html { render :new, status: :unprocessable_entity }
    end
  end
  end

  
  private

  def question_params
    params.require(:question).permit(:content, :options, :correct_answer)
  end  
end

