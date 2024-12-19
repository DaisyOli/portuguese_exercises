Rails.application.routes.draw do
  # Rota inicial
  root to: 'home#index'

  # Rotas para dashboards
  get 'teachers/dashboard', to: 'teachers#dashboard', as: :teacher_dashboard
  get 'students/dashboard', to: 'students#dashboard', as: :student_dashboard

  # Rotas do Devise para autenticação
  devise_for :users

  # Rotas para atividades
  resources :activities

  # Health check para monitoramento
  get "up" => "rails/health#show", as: :rails_health_check
end
