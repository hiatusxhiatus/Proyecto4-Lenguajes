Rails.application.routes.draw do
  root 'products#index'
  
  resources :products, except: [:edit] do
    member do
      patch :update_stock
    end
  end
  
  resources :tax_rates
  
  resources :invoices do
    member do
      post :add_item
      delete 'remove_item/:item_index', to: 'invoices#remove_item', as: :remove_item
      post :finalize
      get :download_pdf
    end
  end
  
  get '/health', to: proc { [200, {}, ['OK']] }
end