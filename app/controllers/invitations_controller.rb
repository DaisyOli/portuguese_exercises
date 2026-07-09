class InvitationsController < Devise::InvitationsController
  skip_before_action :authenticate_user!, only: [:edit, :update]

  before_action :require_teacher_or_admin!, only: [:new, :create]
  before_action :force_trial_role_for_teachers, only: [:create]
  before_action :configure_permitted_parameters

  def after_invite_path_for(resource)
    current_user.admin? ? admin_root_path : teacher_dashboard_path
  end

  def after_accept_path_for(resource)
    return teacher_dashboard_path if resource.teacher?
    return billing_new_path if resource.trial?
    student_dashboard_path
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:invite, keys: [:name, :role, :level, :professional_type])
    devise_parameter_sanitizer.permit(:accept_invitation, keys: [:name, :weekly_reminder_email])
  end

  private

  def require_teacher_or_admin!
    unless current_user&.teacher? || current_user&.admin?
      redirect_to root_path, alert: t('messages.permission_denied') and return
    end
  end

  def force_trial_role_for_teachers
    params[:user] ||= {}
    return if current_user.admin?
    params[:user][:role] = "trial"
  end
end