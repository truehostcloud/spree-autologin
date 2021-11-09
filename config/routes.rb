Spree::Core::Engine.add_routes do
  # Add your extension routes here
  root :to => 'spree/admin/orders'
  get '/admin/auto_login/:user' => 'users#index'
end
