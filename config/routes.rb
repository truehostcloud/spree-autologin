Spree::Core::Engine.add_routes do
  post 'ryanada/auth', controller: 'custom_user_auth', action: 'auto_login'
end
