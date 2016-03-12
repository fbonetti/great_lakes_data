Rails.application.routes.draw do
  resources :readings, only: [:index] do
    collection do
      get :daily_average
    end
  end
end
