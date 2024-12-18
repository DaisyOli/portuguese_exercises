class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?



  def after_sign_in_path_for(resource)
    case resource.role
    when 'teacher'
      teacher_dashboard_path # Substitua pelo caminho correto
    when 'student'
      student_dashboard_path # Substitua pelo caminho correto
    else
      root_path
    end
  end
  
  protected

  def configure_permitted_parameters
    # Permite o atributo `role` durante o signup e update
    devise_parameter_sanitizer.permit(:sign_up, keys: [:role])
    devise_parameter_sanitizer.permit(:account_update, keys: [:role])
  end
end

