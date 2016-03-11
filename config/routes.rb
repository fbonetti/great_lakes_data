Rails.application.routes.draw do
  resources :readings, only: [:index] do
    collection do
      get :search
    end
  end
end
