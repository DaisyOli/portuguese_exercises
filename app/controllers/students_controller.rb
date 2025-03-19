class StudentsController < ApplicationController
  def dashboard
    if params[:level].present?
      @activities = Activity.where(level: params[:level])
      @current_level = params[:level]
    else
      @activities = Activity.all
      @activities_by_level = Activity.all.group_by(&:level)
    end
  end
end
