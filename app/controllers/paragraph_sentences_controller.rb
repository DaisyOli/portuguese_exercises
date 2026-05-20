class ParagraphSentencesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_activity
  before_action :set_paragraph_ordering
  before_action :require_teacher!

  def create
    @paragraph_ordering.add_sentence(params[:paragraph_sentence][:sentence])
    redirect_to activity_path(@activity), notice: t('paragraph_orderings.created')
  rescue ActiveRecord::RecordInvalid => e
    redirect_to activity_path(@activity), alert: e.message
  end

  def destroy
    @paragraph_ordering.paragraph_sentences.find(params[:id]).destroy
    @paragraph_ordering.send(:shuffle_display_positions!)
    redirect_to activity_path(@activity), notice: t('paragraph_orderings.destroyed')
  end

  private

  def set_activity
    @activity = Activity.find_by!(slug: params[:activity_slug])
  end

  def set_paragraph_ordering
    @paragraph_ordering = @activity.paragraph_orderings.find(params[:paragraph_ordering_id])
  end

  def require_teacher!
    redirect_to root_path, alert: t('devise.failure.unauthenticated') and return unless current_user.teacher?
  end
end
