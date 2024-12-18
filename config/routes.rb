Rails.application.routes.draw do
  get 'students/dashboard'
  get 'teachers/dashboard'
  get 'home/index'
  devise_for :users
  root to: 'home#index'
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  get 'teachers/dashboard', to: 'teachers#dashboard', as: :teacher_dashboard
  get 'students/dashboard', to: 'students#dashboard', as: :student_dashboard
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
