class ActivitiesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_activity, only: [:show, :edit, :update, :destroy]

  def index
    @activities = Activity.all
  end

  def show
  end

  def new
    @activity = current_user.activities.new
  end

  def create
    @activity = current_user.activities.new(activity_params)
    if @activity.save
      redirect_to teacher_dashboard_path, notice: "Activity was successfully created"
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
      render :edit
    end
  end

  def destroy
    @activity.destroy
    redirect_to activities_path, notice: "Activity was successfully deleted"
  end
  
  private

  # Define o @activity para ações como show, edit, update e destroy
  def set_activity
    @activity = current_user.activities.find(params[:id])
  end

  # Define os parâmetros permitidos para criar ou atualizar atividades
  def activity_params
    params.require(:activity).permit(:title, :description, :content_type, :content_url, :level)
  end
end
