Rails.application.routes.draw do
  resources :readings, only: [:index] do
    collection do
      get :station_data
    end
  end
end
