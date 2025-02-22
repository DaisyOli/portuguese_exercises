class LanguagesController < ApplicationController
  def update
    new_language = params[:language].to_s

    if current_user.update(language: new_language)
      session[:locale] = new_language
      I18n.locale = new_language.to_sym
      flash[:notice] = t('messages.language_updated')
      redirect_to request.referer || root_path, allow_other_host: false
    else
      flash[:alert] = t('messages.language_update_failed')
      redirect_to request.referer || root_path, allow_other_host: false
    end
  end
end 