Rails.application.routes.draw do
  root 'welcome#index'
  get 'welcome/index'
  get 'welcome/refresh'
  post 'welcome/login'
  get 'welcome/home'
  post 'welcome/trigger'
  post 'welcome/start'
  post 'welcome/play'
  get 'welcome/logout'
  get 'image/:filename' => 'welcome#image'
end
