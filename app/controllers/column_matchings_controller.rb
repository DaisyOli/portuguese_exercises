class ColumnMatchingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_activity
  before_action :require_teacher!

  def create
    @column_matching = @activity.column_matchings.build(column_matching_params)
    if @column_matching.save
      pairs = params[:pairs]&.values&.reject { |p| p[:left].blank? && p[:right].blank? } || []
      pairs.each_with_index do |pair, i|
        next if pair[:left].blank? || pair[:right].blank?
        @column_matching.matching_pairs.create!(
          left_item: pair[:left].strip,
          right_item: pair[:right].strip,
          position: i + 1
        )
      end
      redirect_to activity_path(@activity, ultimo_conteudo: "column-matching-#{@column_matching.id}"),
                  notice: t('column_matchings.created')
    else
      redirect_to activity_path(@activity), alert: @column_matching.errors.full_messages.join(", ")
    end
  end

  def update
    @column_matching = @activity.column_matchings.find(params[:id])
    if @column_matching.update(column_matching_params)
      redirect_to activity_path(@activity), notice: t('column_matchings.updated')
    else
      redirect_to activity_path(@activity), alert: @column_matching.errors.full_messages.join(", ")
    end
  end

  def destroy
    @activity.column_matchings.find(params[:id]).destroy
    redirect_to activity_path(@activity), notice: t('column_matchings.destroyed')
  end

  private

  def set_activity
    @activity = Activity.find_by!(slug: params[:activity_slug])
  end

  def require_teacher!
    redirect_to root_path, alert: t('devise.failure.unauthenticated') and return unless current_user.teacher?
  end

  def column_matching_params
    params.require(:column_matching).permit(:title, :instruction)
  end
end
