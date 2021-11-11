Spree::Core::Engine.add_routes do
  devise_scope :spree_user do
    post 'ryanada/auth', controller: 'custom_user_auth', action: 'auto_login'
  end
end
