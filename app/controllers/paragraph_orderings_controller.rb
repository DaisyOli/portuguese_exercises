class ParagraphOrderingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_activity
  before_action :require_teacher!

  def create
    @paragraph_ordering = @activity.paragraph_orderings.build(paragraph_ordering_params)
    if @paragraph_ordering.save
      sentences = params[:sentences]&.values&.reject(&:blank?) || []
      sentences.each { |text| @paragraph_ordering.add_sentence(text) }
      redirect_to activity_path(@activity, ultimo_conteudo: "paragraph-ordering-#{@paragraph_ordering.id}"), notice: t('paragraph_orderings.created')
    else
      redirect_to activity_path(@activity), alert: @paragraph_ordering.errors.full_messages.join(", ")
    end
  end

  def update
    @paragraph_ordering = @activity.paragraph_orderings.find(params[:id])
    if @paragraph_ordering.update(paragraph_ordering_params)
      redirect_to activity_path(@activity), notice: t('paragraph_orderings.updated')
    else
      redirect_to activity_path(@activity), alert: @paragraph_ordering.errors.full_messages.join(", ")
    end
  end

  def destroy
    @activity.paragraph_orderings.find(params[:id]).destroy
    redirect_to activity_path(@activity), notice: t('paragraph_orderings.destroyed')
  end

  private

  def set_activity
    @activity = Activity.find_by!(slug: params[:activity_slug])
  end

  def require_teacher!
    redirect_to root_path, alert: t('devise.failure.unauthenticated') and return unless current_user.teacher?
  end

  def paragraph_ordering_params
    params.require(:paragraph_ordering).permit(:title, :instruction)
  end
end
