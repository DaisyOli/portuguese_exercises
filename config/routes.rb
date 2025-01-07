Rails.application.routes.draw do
  # Rota inicial
  root to: 'home#index'

  # Rotas para dashboards
  get 'teachers/dashboard', to: 'teachers#dashboard', as: :teacher_dashboard
  get 'students/dashboard', to: 'students#dashboard', as: :student_dashboard
  
  # Rotas do Devise para autenticação
  devise_for :users

  # Rotas para atividades
  resources :activities do
    member do
      get :resolve_quiz
      post :submit_quiz
      get :quiz_results
    end

    resources :questions
  end

  # Health check para monitoramento
  get "up" => "rails/health#show", as: :rails_health_check
end
