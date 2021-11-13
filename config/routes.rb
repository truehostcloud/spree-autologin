Spree::Core::Engine.routes.draw do
  post 'admin/auto_login', controller: 'olitt/users', action: 'auto_login'
end
