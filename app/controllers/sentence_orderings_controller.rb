class SentenceOrderingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_activity
  before_action :require_teacher!

  def create
    @sentence_ordering = @activity.sentence_orderings.build(sentence_ordering_params)
    if @sentence_ordering.save
      redirect_to activity_path(@activity, ultimo_conteudo: "sentence-ordering-#{@sentence_ordering.id}"), notice: t('sentence_orderings.created')
    else
      redirect_to activity_path(@activity), alert: @sentence_ordering.errors.full_messages.join(", ")
    end
  end

  def update
    @sentence_ordering = @activity.sentence_orderings.find(params[:id])
    if @sentence_ordering.update(sentence_ordering_params)
      redirect_to activity_path(@activity), notice: t('sentence_orderings.updated')
    else
      redirect_to activity_path(@activity), alert: @sentence_ordering.errors.full_messages.join(", ")
    end
  end

  def destroy
    @sentence_ordering = @activity.sentence_orderings.find(params[:id])
    @sentence_ordering.destroy
    redirect_to activity_path(@activity), notice: t('sentence_orderings.destroyed')
  end

  private

  def set_activity
    @activity = Activity.find_by!(slug: params[:activity_slug])
  end

  def require_teacher!
    redirect_to root_path, alert: t('devise.failure.unauthenticated') and return unless current_user.teacher?
  end

  def sentence_ordering_params
    params.require(:sentence_ordering).permit(:sentence, :instruction)
  end
end
