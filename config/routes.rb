Spree::Core::Engine.add_routes do
  # Add your extension routes here
  get 'spree/admin/auto_login/:user' => 'users#index'

  resources :scratch, only: [:index], controller: 'scratch'
  # resources :tests, only: [:index, :show, :new, :create], controller: 'ryanada/tests'
end
