class StudentsController < ApplicationController
  include QuizManagement

  ACTIVITIES_PER_PAGE = 3

  def dashboard
    load_completed_exercises if current_user.student?

    if params[:level].present?
      @current_level = params[:level]
      load_level_activities
    else
      @activities_by_level = Activity.published.group_by(&:level)
    end
  end

  def load_more
    load_completed_exercises if current_user.student?
    
    level = params[:level]
    offset = params[:offset].to_i
    
    completed_ids = session[:completed_quizzes] || []
    activities = Activity.published
                        .where(level: level)
                        .where.not(id: completed_ids)
                        .with_questions_count
                        .with_attached_image_file
                        .with_attached_video_file
                        .with_attached_audio_file
                        .includes(:teacher)
                        .limit(ACTIVITIES_PER_PAGE)
                        .offset(offset)

    total_pending = Activity.published.where(level: level).where.not(id: completed_ids).count
    has_more = (offset + ACTIVITIES_PER_PAGE) < total_pending
    
    render json: {
      html: render_to_string(partial: 'activities_grid', locals: { activities: activities }),
      has_more: has_more,
      next_offset: offset + ACTIVITIES_PER_PAGE,
      remaining: [total_pending - offset - ACTIVITIES_PER_PAGE, 0].max
    }
  end
  
  def toggle_weekly_reminder
    current_user.update!(weekly_reminder_email: !current_user.weekly_reminder_email?)
    redirect_to student_dashboard_path
  end

  def open_ended_attempts
    per_page = 3
    offset   = params[:offset].to_i

    all_cards = QuizAttempt
      .where(user: current_user)
      .includes(:activity)
      .order(submitted_at: :desc)
      .to_a
      .select { |a| a.open_ended_results.any? }
      .flat_map { |attempt|
        attempt.open_ended_results.map { |q_key, result|
          { attempt: attempt, q_key: q_key, result: result }
        }
      }

    total      = all_cards.size
    page_cards = all_cards[offset, per_page] || []

    html = page_cards.map { |card|
      render_to_string(
        partial: 'students/open_ended_card',
        locals: { attempt: card[:attempt], q_key: card[:q_key], result: card[:result] },
        formats: [:html]
      )
    }.join

    render json: {
      html:        html,
      has_more:    (offset + per_page) < total,
      next_offset: offset + per_page
    }
  end

  private
  
  def load_level_activities
    completed_ids = session[:completed_quizzes] || []

    @pending_activities = Activity.published
                                  .by_level(@current_level)
                                  .where.not(id: completed_ids)
                                  .with_questions_count
                                  .with_attached_image_file
                                  .with_attached_video_file
                                  .with_attached_audio_file
                                  .includes(:teacher, :activity_ratings)
                                  .limit(ACTIVITIES_PER_PAGE)
    @total_pending        = Activity.published.by_level(@current_level).where.not(id: completed_ids).count
    @completed_activities = Activity.published
                                    .by_level(@current_level)
                                    .where(id: completed_ids)
                                    .with_questions_count
                                    .with_attached_image_file
                                    .with_attached_video_file
                                    .with_attached_audio_file
                                    .includes(:teacher, :activity_ratings)
    @activities = @pending_activities
  end
  
end
