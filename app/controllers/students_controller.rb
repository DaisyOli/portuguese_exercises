class StudentsController < ApplicationController
  def dashboard
    if params[:level].present?
      @activities = Activity.where(level: params[:level])
      @current_level = params[:level]
    else
      @activities = Activity.all
      @activities_by_level = Activity.all.group_by(&:level)
    end
    
    # Carregar exercícios completados pelo aluno para a sessão
    if current_user && current_user.student?
      load_completed_exercises
    end
  end
  
  private
  
  def load_completed_exercises
    # Inicializar array de exercícios concluídos na sessão se não existir
    session[:completed_quizzes] ||= []
    
    # Carregar todos os quiz_attempts do usuário atual
    completed_activities = current_user.quiz_attempts
                                      .select(:activity_id)
                                      .distinct
                                      .pluck(:activity_id)
    
    # Atualizar a sessão com os IDs de atividades concluídas
    completed_activities.each do |activity_id|
      session[:completed_quizzes] << activity_id unless session[:completed_quizzes].include?(activity_id)
    end
  end
end
