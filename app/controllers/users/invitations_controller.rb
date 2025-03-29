class Users::InvitationsController < Devise::InvitationsController
  skip_before_action :authenticate_user!, only: [:edit, :update]
  
  # GET /resource/invitation/accept?invitation_token=abcdef
  def edit
    # Esta é a ação que mostra o formulário de aceitação do convite
    # e definição de senha
    set_minimum_password_length
    resource.invitation_token = params[:invitation_token]
    Rails.logger.info("Editing invitation with token: #{params[:invitation_token]}")
    super
  end

  # PUT /resource/invitation
  def update
    # Esta é a ação que processa o formulário de aceitação
    Rails.logger.info("Updating invitation with parameters: #{params.inspect}")
    super
  end

  protected

  def after_accept_path_for(resource)
    # Após aceitar o convite com sucesso, 
    # redireciona para o dashboard apropriado
    if resource.teacher?
      teacher_dashboard_path
    elsif resource.student?
      student_dashboard_path
    else
      root_path
    end
  end
end 