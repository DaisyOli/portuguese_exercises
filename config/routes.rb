Rails.application.routes.draw do
  # Rota inicial
  root to: 'home#index'

  # Rotas para dashboards
  get 'teachers/dashboard', to: 'teachers#dashboard', as: :teacher_dashboard
  get 'students/dashboard', to: 'students#dashboard', as: :student_dashboard
  
  # Rota para atualização de idioma
  patch 'update_language', to: 'languages#update', as: :update_language
  
  # Rotas do Devise para autenticação
  devise_for :users, controllers: {
    invitations: 'invitations'
  }

  # Rotas para atividades e questões
  resources :activities do
    member do
      get :resolve_quiz
      post :submit_quiz
      get :quiz_results
      patch :clear_statement
      patch :clear_media
      patch :clear_explanation
    end

    resources :questions
  end

  # Health check para monitoramento
  get "up" => "rails/health#show", as: :rails_health_check

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end
end
