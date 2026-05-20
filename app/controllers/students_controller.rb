class StudentsController < ApplicationController
  include QuizManagement

  ACTIVITIES_PER_PAGE = 3

  def dashboard
    load_completed_exercises if current_user.student?

    if params[:level].present?
      @current_level = params[:level]
      load_level_activities
    else
      @activities = Activity.all
      @activities_by_level = Activity.all.group_by(&:level)
    end
  end

  def load_more
    load_completed_exercises if current_user.student?
    
    level = params[:level]
    offset = params[:offset].to_i
    
    completed_ids = session[:completed_quizzes] || []
    activities = Activity.where(level: level)
                        .where.not(id: completed_ids)
                        .with_questions_count
                        .limit(ACTIVITIES_PER_PAGE)
                        .offset(offset)
    
    total_pending = Activity.where(level: level).where.not(id: completed_ids).count
    has_more = (offset + ACTIVITIES_PER_PAGE) < total_pending
    
    render json: {
      html: render_to_string(partial: 'activities_grid', locals: { activities: activities }),
      has_more: has_more,
      next_offset: offset + ACTIVITIES_PER_PAGE,
      remaining: [total_pending - offset - ACTIVITIES_PER_PAGE, 0].max
    }
  end
  
  private
  
  def load_level_activities
    completed_ids = session[:completed_quizzes] || []

    @pending_activities = Activity.by_level(@current_level)
                                  .where.not(id: completed_ids)
                                  .with_questions_count
                                  .limit(ACTIVITIES_PER_PAGE)
    @total_pending        = Activity.by_level(@current_level).where.not(id: completed_ids).count
    @completed_activities = Activity.by_level(@current_level).where(id: completed_ids).with_questions_count
    @activities = @pending_activities
  end
  
end
