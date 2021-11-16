Spree::Core::Engine.routes.draw do
  get 'admin/auto_login', controller: 'olitt/users', action: 'auto_login'
end
