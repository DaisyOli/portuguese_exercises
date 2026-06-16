class TeacherCommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_teacher!

  def update
    @attempt = QuizAttempt
      .joins(:activity)
      .where(activities: { teacher_id: current_user.id })
      .find(params[:id])

    key      = "question_#{params[:question_id]}"
    comments = (@attempt.teacher_comments || {}).merge(key => params[:comment].presence).compact
    @attempt.update!(teacher_comments: comments)

    redirect_back fallback_location: teacher_student_profile_path(@attempt.user_id),
                  notice: "Feedback salvo."
  end

  private

  def require_teacher!
    redirect_to root_path unless current_user&.teacher?
  end
end
