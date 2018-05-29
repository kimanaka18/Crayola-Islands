Rails.application.routes.draw do
  get 'game/view'

  get 'game/edit'
  
  get 'game/create'

  get 'game/randomize'
  
  get 'sessions/new'
  
  get 'game/delete'

  post '/login', to: 'sessions#create'

  post 'game/edit', to: 'game#modify'
  
  post 'game/create', to: 'game#createUser'
  
  post 'game/delete', to: 'game#deleteUser'

  post 'game/randomize', to: 'game#randomizeMap'

  root 'sessions#new'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
