Rails.application.routes.draw do
  # Rota inicial
  root to: 'home#index'

  # Rotas para dashboards
  get 'student_dashboard', to: 'students#dashboard'
  get 'students/load_more', to: 'students#load_more'
  get 'teacher_dashboard', to: 'teachers#dashboard'
  
  # Rota para atualização de idioma
  patch 'update_language', to: 'languages#update'
  
  # Rotas do Devise para autenticação
  devise_for :users, controllers: {
    invitations: 'invitations'
  }

  # Rotas para atividades e questões
  resources :activities, param: :slug do
    member do
      get :solve, action: :resolve_quiz  # /activities/:slug/solve
      post :submit, action: :submit_quiz # /activities/:slug/submit
      get :results, action: :quiz_results # /activities/:slug/results
      patch :clear_statement
      match :clear_media, via: [:patch, :post]
      patch :clear_explanation
      delete :clear_attempt_history
    end

    resources :questions
    resources :suggestions, only: [:create, :destroy]
  end

  # Health check para monitoramento
  get "up" => "rails/health#show", as: :rails_health_check

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end
end
