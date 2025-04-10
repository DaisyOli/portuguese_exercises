class Users::InvitationsController < Devise::InvitationsController
  # Pula autenticação de forma explícita para estas ações
  skip_before_action :authenticate_user!, only: [:edit, :update]
  
  # GET /resource/invitation/accept?invitation_token=abcdef
  def edit
    begin
      # Esta é a ação que mostra o formulário de aceitação do convite
      # e definição de senha
      set_minimum_password_length
      resource.invitation_token = params[:invitation_token]
      Rails.logger.info("Editing invitation with token present: #{params[:invitation_token]}")
      
      # Verifica se o token é válido
      self.resource = resource_class.find_by_invitation_token(params[:invitation_token], true)
      
      if resource.nil?
        Rails.logger.error("Invalid invitation token: #{params[:invitation_token]}")
        set_flash_message(:alert, :invitation_token_invalid)
        redirect_to after_sign_out_path_for(resource_name) and return
      end
      
      super
    rescue => e
      Rails.logger.error("Error in invitation edit: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      respond_to do |format|
        format.html { render plain: "Erro ao processar o convite. Por favor, entre em contato com o administrador. Erro: #{e.message}", status: 500 }
        format.json { render json: {error: e.message}, status: 500 }
      end
    end
  end

  # PUT /resource/invitation
  def update
    begin
      Rails.logger.info("Updating invitation with parameters: #{params.inspect}")
      
      # Verifica se o token foi fornecido
      if params[:user].blank? || params[:user][:invitation_token].blank?
        Rails.logger.error("No invitation token provided in params")
        render plain: "Token de convite não fornecido ou inválido", status: 422
        return
      end
      
      super
    rescue => e
      Rails.logger.error("Error in invitation update: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      respond_to do |format|
        format.html { render plain: "Erro ao aceitar o convite. Por favor, entre em contato com o administrador. Erro: #{e.message}", status: 500 }
        format.json { render json: {error: e.message}, status: 500 }
      end
    end
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