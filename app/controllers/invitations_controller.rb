class InvitationsController < Devise::InvitationsController
  before_action :authenticate_user!
  before_action :require_teacher, only: [:new, :create]

  private

  def require_teacher
    unless current_user&.teacher?
      redirect_to root_path, alert: t('messages.permission_denied')
    end
  end

  # Permite definir o role no convite
  def invite_params
    params.require(:user).permit(:email, :role)
  end

  # Configura parâmetros adicionais ao criar o convite
  def invite_resource(&block)
    # Define role como 'student' por padrão
    resource_class.invite!(invite_params.merge(role: 'student'), current_user, &block)
  end
end 