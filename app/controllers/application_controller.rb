class ApplicationController < ActionController::Base
  # Autenticação padrão
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :check_trial_restrictions!
  around_action :switch_locale

  def after_sign_in_path_for(resource)
    if resource.teacher?
      teacher_dashboard_path
    elsif resource.student_like?
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

  def check_trial_restrictions!
    return unless current_user&.trial?
    return if devise_controller?
    return if controller_name == "billing"
    return if controller_name == "webhooks"

    if current_user.invitation_accepted_at.present?
      # Aluno convidado pelo professor: redireciona para assinatura
      redirect_to billing_new_path
    else
      # Aluno da landing page: trial de 3 atividades ou 7 dias
      return if controller_name == "home" && action_name == "trial_expired"
      redirect_to trial_expired_path if current_user.trial_expired? || current_user.trial_exhausted?
    end
  end

  def switch_locale(&action)
    I18n.with_locale(I18n.default_locale, &action)
  end
end

