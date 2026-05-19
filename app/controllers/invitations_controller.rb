class InvitationsController < Devise::InvitationsController
  before_action :require_teacher!, only: [:new, :create]
  before_action :configure_permitted_parameters

  def after_invite_path_for(resource)
    teacher_dashboard_path
  end

  def after_accept_path_for(resource)
    resource.teacher? ? teacher_dashboard_path : student_dashboard_path
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:invite, keys: [:name, :role])
    devise_parameter_sanitizer.permit(:accept_invitation, keys: [:name])
  end

  private

  def require_teacher!
    unless current_user&.teacher?
      redirect_to root_path, alert: t('messages.permission_denied') and return
    end
  end
end