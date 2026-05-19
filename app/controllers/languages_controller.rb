class LanguagesController < ApplicationController
  def update
    new_language = params[:language].to_s

    if User::LANGUAGES.include?(new_language)
      if current_user.update(language: new_language)
        session[:locale] = new_language
        I18n.locale = new_language.to_sym
        flash[:notice] = t('messages.language_updated')
      else
        Rails.logger.error "Failed to update user language: #{current_user.errors.full_messages.join(', ')}"
        flash[:alert] = t('messages.language_update_failed')
      end
    else
      flash[:alert] = t('messages.language_update_failed')
    end

    redirect_to request.referer || root_path, allow_other_host: false
  end
end 