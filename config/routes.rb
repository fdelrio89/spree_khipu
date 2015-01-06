Spree::Core::Engine.routes.draw do
  post '/khipu', to: "khipu#pay", as: :khipu
  get '/khipu/success/:payment', to: "khipu#success", as: :khipu_success
  get '/khipu/cancel/:payment', to: "khipu#cancel", as: :khipu_cancel
  post '/khipu/notify'
end
