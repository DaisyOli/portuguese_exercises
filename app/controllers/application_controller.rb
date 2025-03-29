class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_locale, if: :user_signed_in?
  around_action :switch_locale

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
    devise_parameter_sanitizer.permit(:sign_up, keys: [:role, :name, :language])
    devise_parameter_sanitizer.permit(:account_update, keys: [:role, :name, :language])
    devise_parameter_sanitizer.permit(:accept_invitation, keys: [:name, :language])
    devise_parameter_sanitizer.permit(:invite, keys: [:name, :role, :language, :email])
  end

  private

  def set_locale
    I18n.locale = if user_signed_in? && current_user
                    current_user.language.to_sym
                  else
                    params[:locale] || I18n.default_locale
                  end
    Rails.logger.info "Locale set to: #{I18n.locale}"
    Rails.logger.info "Available locales: #{I18n.available_locales.inspect}"
  end

  def extract_locale
    locale = if user_signed_in? && current_user
               current_user.language
             else
               params[:locale] || http_accept_language.compatible_language_from(I18n.available_locales)
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

