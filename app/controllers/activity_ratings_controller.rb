class ActivityRatingsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_student!
  before_action :set_activity

  def create
    existing = @activity.rating_by_user(current_user)
    if existing
      update_rating(existing)
    else
      @rating = @activity.activity_ratings.build(rating_params.merge(user: current_user))
      if @rating.save
        render json: rating_response("Avaliação enviada!")
      else
        render json: { status: "error", message: @rating.errors.full_messages.join(", ") }, status: :unprocessable_entity
      end
    end
  end

  def update
    @rating = @activity.activity_ratings.find_by!(user: current_user)
    update_rating(@rating)
  end

  private

  def update_rating(rating)
    if rating.update(rating_params)
      render json: rating_response("Avaliação atualizada!")
    else
      render json: { status: "error", message: rating.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  def rating_response(message)
    {
      status:  "success",
      message: message,
      stars:   @activity.activity_ratings.find_by(user: current_user)&.stars,
      average: @activity.average_rating,
      count:   @activity.ratings_count
    }
  end

  def set_activity
    @activity = Activity.find_by!(slug: params[:activity_slug])
  end

  def rating_params
    params.require(:activity_rating).permit(:stars, :comment)
  end

  def require_student!
    redirect_to root_path, alert: "Apenas alunos podem avaliar atividades." if current_user.teacher?
  end
end
