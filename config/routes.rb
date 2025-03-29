Rails.application.routes.draw do
  # Rota inicial
  root to: 'home#index'

  # Rotas para dashboards
  get 'student_dashboard', to: 'students#dashboard'
  get 'teacher_dashboard', to: 'teachers#dashboard'
  
  # Rota para atualização de idioma
  patch 'update_language', to: 'languages#update'
  
  # Define rotas para convites que não requerem autenticação
  devise_scope :user do
    get '/users/invitation/accept', to: 'users/invitations#edit'
    put '/users/invitation', to: 'users/invitations#update'
  end

  # Rotas do Devise para autenticação
  devise_for :users, controllers: {
    invitations: 'users/invitations'
  }, skip: [:invitations]  # Pula as rotas de convite já definidas acima

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
