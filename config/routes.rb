Spree::Core::Engine.add_routes do
  # Add your extension routes here
  get 'spree/admin/auto_login/:user' => 'users#index'
end
