class TasksController < ApplicationController
  before_action :set_activity

  def new
    @task = @activity.tasks.build
  end

  def create
    @task = @activity.tasks.build(task_params)
  
    if params[:task][:correct_answers].present?
      @task.correct_answers = params[:task][:correct_answers].split(',').map(&:strip)
    end
  
    if @task.save
      redirect_to activity_task_path(@activity, @task), notice: "Task created successfully!"
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { 
          render turbo_stream: turbo_stream.replace("task_form", 
            partial: "tasks/form", 
            locals: { task: @task, activity: @activity }
          )
        }
      end
    end
  end
  
  
  def show
    @task = @activity.tasks.find(params[:id])
  end
  
  private

  def set_activity
    @activity = Activity.find(params[:activity_id])
  end

  def set_task
    @task = @activity.tasks.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:description, :content, :correct_answers)
  end
end

