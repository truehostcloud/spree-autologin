Spree::Core::Engine.add_routes do
  get 'spree/admin/auto_login/:user' => 'users#index'
  post 'ryanada/auth', controller: 'custom_user_auth', action: 'create'
end
