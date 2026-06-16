class TeachersController < ApplicationController
  before_action :authenticate_user!, except: []
  before_action :require_teacher!, only: [:students, :student_profile, :update_student_level, :remove_student, :clear_student_comments, :more_ratings]

  def dashboard
  end

  def more_ratings
    offset   = params[:offset].to_i
    per_page = 3

    ratings = ActivityRating
      .joins(:activity, :user)
      .where(activities: { teacher_id: current_user.id })
      .where.not(comment: [nil, ''])
      .order(created_at: :desc)
      .includes(:user, :activity)
      .limit(per_page)
      .offset(offset)

    total = ActivityRating
      .joins(:activity)
      .where(activities: { teacher_id: current_user.id })
      .where.not(comment: [nil, ''])
      .count

    html = ratings.map { |rating|
      render_to_string(partial: 'teachers/rating_card', locals: { rating: rating }, formats: [:html])
    }.join

    render json: {
      html:        html,
      has_more:    (offset + per_page) < total,
      next_offset: offset + per_page
    }
  end

  def students
    @students = current_user.students
      .left_joins(:quiz_attempts)
      .where(
        "quiz_attempts.id IS NULL OR quiz_attempts.activity_id IN (?)",
        current_user.activities.select(:id)
      )
      .select(
        "users.*",
        "MAX(quiz_attempts.submitted_at) AS last_active",
        "COUNT(DISTINCT quiz_attempts.id) AS total_attempts",
        "ROUND(AVG(quiz_attempts.score)::numeric, 0) AS avg_score"
      )
      .group("users.id")
      .order(Arel.sql("MAX(quiz_attempts.submitted_at) DESC NULLS LAST"))
  end

  def student_profile
    @student = current_user.students.find(params[:id])
    @attempts = QuizAttempt
      .joins(:activity)
      .where(user_id: @student.id, activities: { teacher_id: current_user.id })
      .includes(:activity)
      .order(submitted_at: :desc)

    activity_ids = current_user.activities.pluck(:id)
    attempt_dates = QuizAttempt
      .where(user_id: @student.id, activity_id: activity_ids)
      .where("submitted_at >= ?", 30.days.ago)
      .pluck(:submitted_at)
      .map { |t| t.to_date }
      .uniq
    @days_active = attempt_dates.count

    @avg_score  = @attempts.average(:score)&.round || 0
    @best_score = @attempts.maximum(:score)&.round || 0

    # Open-ended attempts awaiting teacher feedback (for the pending badge)
    @pending_count = @attempts.count { |a| a.open_ended_results.any? && a.teacher_comments.blank? }
  rescue ActiveRecord::RecordNotFound
    redirect_to teacher_students_path, alert: "Aluno não encontrado."
  end

  def update_student_level
    student = current_user.students.find(params[:id])
    new_level = params[:level].presence
    if new_level.nil? || User::CEFR_LEVELS.include?(new_level)
      student.update!(level: new_level)
      redirect_to teacher_student_profile_path(student), notice: "Nível atualizado."
    else
      redirect_to teacher_student_profile_path(student), alert: "Nível inválido."
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to teacher_students_path
  end

  def remove_student
    student = current_user.students.find(params[:id])
    student.update!(invited_by_id: nil)
    redirect_to teacher_students_path, notice: "#{student.display_name} foi removido da sua lista de alunos."
  rescue ActiveRecord::RecordNotFound
    redirect_to teacher_students_path
  end

  def clear_student_comments
    student = current_user.students.find(params[:id])
    QuizAttempt
      .joins(:activity)
      .where(user_id: student.id, activities: { teacher_id: current_user.id })
      .update_all(teacher_comments: {})
    redirect_to teacher_student_profile_path(student), notice: "Feedbacks apagados."
  rescue ActiveRecord::RecordNotFound
    redirect_to teacher_students_path
  end

  private

  def require_teacher!
    redirect_to root_path unless current_user&.teacher?
  end
end
