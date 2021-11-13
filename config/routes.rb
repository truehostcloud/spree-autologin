Spree::Core::Engine.routes.draw do
  namespace :spree_user do
    post 'admin/auto_login', controller: 'olitt/users', action: 'auto_login'
  end
end
