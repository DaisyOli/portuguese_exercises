class MatchingPairsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_activity
  before_action :set_column_matching
  before_action :require_teacher!

  def create
    left  = params[:matching_pair][:left_item].to_s.strip
    right = params[:matching_pair][:right_item].to_s.strip

    if left.blank? || right.blank?
      redirect_to activity_path(@activity), alert: t('column_matchings.pair_blank')
      return
    end

    @column_matching.add_pair(left, right)
    redirect_to activity_path(@activity), notice: t('column_matchings.pair_added')
  end

  def destroy
    @column_matching.matching_pairs.find(params[:id]).destroy
    redirect_to activity_path(@activity), notice: t('column_matchings.pair_removed')
  end

  private

  def set_activity
    @activity = Activity.find_by!(slug: params[:activity_slug])
  end

  def set_column_matching
    @column_matching = @activity.column_matchings.find(params[:column_matching_id])
  end

  def require_teacher!
    redirect_to root_path, alert: t('devise.failure.unauthenticated') and return unless current_user.teacher?
  end
end
