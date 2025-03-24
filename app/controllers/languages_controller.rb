class LanguagesController < ApplicationController
  def update
    new_language = params[:language].to_s
    Rails.logger.info "Changing language to: #{new_language}"
    
    # Verificar se é um locale válido
    if User::LANGUAGES.include?(new_language)
      if current_user.update(language: new_language)
        session[:locale] = new_language
        I18n.locale = new_language.to_sym
        Rails.logger.info "Language updated successfully, locale set to: #{I18n.locale}"
        flash[:notice] = t('messages.language_updated')
      else
        Rails.logger.error "Failed to update user language: #{current_user.errors.full_messages.join(', ')}"
        flash[:alert] = t('messages.language_update_failed')
      end
    else
      Rails.logger.error "Invalid language requested: #{new_language}, available: #{User::LANGUAGES.inspect}"
      flash[:alert] = "Invalid language selection. Available languages: #{User::LANGUAGES.join(', ')}"
    end
    
    # Para depuração, tenta obter algumas traduções em diferentes idiomas
    Rails.logger.info "Testing translations:"
    Rails.logger.info "EN: #{I18n.t('quiz.xp_earned', locale: :en)}"
    Rails.logger.info "PT: #{I18n.t('quiz.xp_earned', locale: :pt)}"
    Rails.logger.info "FR: #{I18n.t('quiz.xp_earned', locale: :fr)}"
    
    redirect_to request.referer || root_path, allow_other_host: false
  end
end 