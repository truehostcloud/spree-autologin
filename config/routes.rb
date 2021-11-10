Spree::Core::Engine.routes.draw do
  namespace :admin do
    get '/auto_login' => 'users#create' 
  end
end
