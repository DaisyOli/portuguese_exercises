class SuggestionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_activity
  before_action :authorize_teacher
  
  def create
    @suggestion = @activity.suggestions.new(suggestion_params)
    
    if @suggestion.save
      redirect_to activity_path(@activity, ultimo_conteudo: 'suggestion'), notice: t('messages.suggestion_created')
    else
      redirect_to activity_path(@activity), alert: t('messages.suggestion_create_error')
    end
  end
  
  def destroy
    @suggestion = @activity.suggestions.find(params[:id])
    @suggestion.destroy
    
    redirect_to activity_path(@activity), notice: t('messages.suggestion_deleted')
  end
  
  private
  
  def set_activity
    @activity = Activity.find(params[:activity_id])
  end
  
  def authorize_teacher
    unless current_user.teacher? && @activity.teacher == current_user
      redirect_to activities_path, alert: t('messages.permission_denied')
    end
  end
  
  def suggestion_params
    params.require(:suggestion).permit(:content)
  end
end 