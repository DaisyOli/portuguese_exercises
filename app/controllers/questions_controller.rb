class QuestionsController < ApplicationController
  def new
    @activity = Activity.find(params[:activity_id])
    @question = @activity.questions.build
  end

  def create
    @activity = Activity.find(params[:activity_id])
    @question = @activity.questions.build(question_params)

    # Processa as opções da string separada por vírgulas para um array
    if params[:question][:options].present?
      @question.options = params[:question][:options].split(",").map(&:strip)
    end

    if @question.save
      redirect_to activity_path(@activity), notice: "Questão adicionada com sucesso!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def question_params
    params.require(:question).permit(:content, :correct_answer)
  end
end

