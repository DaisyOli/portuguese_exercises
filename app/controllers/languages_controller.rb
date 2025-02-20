class LanguagesController < ApplicationController
  def update
    new_language = params[:language].to_s

    if current_user.update(language: new_language)
      session[:locale] = new_language
      I18n.locale = new_language.to_sym
      flash[:notice] = "Idioma alterado com sucesso!"
      redirect_to request.referer || root_path, allow_other_host: false
    else
      flash[:alert] = "Não foi possível alterar o idioma."
      redirect_to request.referer || root_path, allow_other_host: false
    end
  end
end 