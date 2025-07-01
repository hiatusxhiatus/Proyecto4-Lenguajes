# config/routes.rb
Rails.application.routes.draw do
  # Ruta principal
  root 'products#index'
  
  # Rutas de productos
  resources :products do
    member do
      patch :update_stock
    end
  end
  
  # Rutas de tasas de impuesto
  resources :tax_rates
  
  # Rutas de facturas
  resources :invoices do
    member do
      post :add_item
      delete 'remove_item/:item_index', to: 'invoices#remove_item', as: :remove_item
      post :finalize
      get :download_pdf
    end
  end
  
  # Ruta de salud (opcional, para verificar que la app funciona)
  get '/health', to: proc { [200, {}, ['OK']] }
end