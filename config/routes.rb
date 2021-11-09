Spree::Core::Engine.routes.draw do
  namespace :backend do
    get '/admin/auto_login' => 'users#create'
  end
end
