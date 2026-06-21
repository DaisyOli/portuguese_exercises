class InvitationsController < Devise::InvitationsController
  skip_before_action :authenticate_user!, only: [:edit, :update]

  before_action :require_teacher_or_admin!, only: [:new, :create]
  before_action :force_student_role_for_teachers, only: [:create]
  before_action :configure_permitted_parameters

  def after_invite_path_for(resource)
    current_user.admin? ? admin_root_path : teacher_dashboard_path
  end

  def after_accept_path_for(resource)
    resource.teacher? ? teacher_dashboard_path : student_dashboard_path
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:invite, keys: [:name, :role, :level])
    devise_parameter_sanitizer.permit(:accept_invitation, keys: [:name])
  end

  private

  def require_teacher_or_admin!
    unless current_user&.teacher? || current_user&.admin?
      redirect_to root_path, alert: t('messages.permission_denied') and return
    end
  end

  def force_student_role_for_teachers
    return if current_user&.admin?
    params[:user] ||= {}
    params[:user][:role] = "student"
  end
end