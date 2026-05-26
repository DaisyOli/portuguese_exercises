class ApplicationController < ActionController::Base
  # Autenticação padrão
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  around_action :switch_locale

  def after_sign_in_path_for(resource)
    if resource.teacher?
      teacher_dashboard_path
    elsif resource.student?
      student_dashboard_path
    else
      root_path
    end
  end
  
  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :language])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :language])
    devise_parameter_sanitizer.permit(:accept_invitation, keys: [:name, :language])
    devise_parameter_sanitizer.permit(:invite, keys: [:name, :role, :language, :email])
  end

  private

  def switch_locale(&action)
    I18n.with_locale(I18n.default_locale, &action)
  end
end

