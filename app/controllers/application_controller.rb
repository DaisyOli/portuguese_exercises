class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_locale, if: :user_signed_in?
  skip_before_action :set_locale, if: :should_skip_locale
  around_action :switch_locale, unless: :should_skip_locale

  def after_sign_in_path_for(resource)
    case resource.role
    when 'teacher'
      teacher_dashboard_path
    when 'student'
      student_dashboard_path
    else
      root_path
    end
  end
  
  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:role])
    devise_parameter_sanitizer.permit(:account_update, keys: [:role])
  end

  private
  
  def should_skip_locale
    devise_controller? && (action_name == 'create' || action_name == 'new')
  end

  def set_locale
    I18n.locale = current_user.language.to_sym if user_signed_in? && current_user.present?
  end

  def extract_locale
    # Evita completamente acessar current_user durante processos de autenticação
    return params[:locale] || I18n.default_locale if devise_controller?
    
    locale = if params[:locale].present?
               params[:locale]
             elsif user_signed_in? && current_user.present?
               current_user.language
             else
               I18n.default_locale
             end
    
    locale.presence || I18n.default_locale
  end

  def switch_locale(&action)
    locale = extract_locale
    I18n.with_locale(locale, &action)
  end

  def default_url_options
    { locale: I18n.locale }
  end
end

