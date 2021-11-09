Spree::Core::Engine.routes.draw do
  namespace :backend do
    get 'admin/auto_login/:user' => 'users#index'
  end
end

