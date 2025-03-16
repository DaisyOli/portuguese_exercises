class InvitationsController < Devise::InvitationsController
  before_action :configure_permitted_parameters

  # Sobrescrevendo métodos do controlador de convites do Devise, se necessário
  # Por exemplo, poderíamos personalizar após o envio do convite:
  def after_invite_path_for(resource)
    teacher_dashboard_path
  end

  # Personalização dos parâmetros permitidos
  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:invite, keys: [:name, :role])
  end
end 