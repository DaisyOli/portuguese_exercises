class InvitationsController < Devise::InvitationsController
  before_action :configure_permitted_parameters
  
  # Sobrescrevendo métodos do controlador de convites do Devise, se necessário
  # Por exemplo, poderíamos personalizar após o envio do convite:
  def after_invite_path_for(resource)
    teacher_dashboard_path
  end
  
  protected
  
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:invite, keys: [:name, :role])
    devise_parameter_sanitizer.permit(:accept_invitation, keys: [:name])
  end
end