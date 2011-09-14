Rails.application.routes.draw do
  namespace :gateway do
    match '/:gateway_id/ccavenue/:order_id' => 'ccavenue#show',     :as => :ccavenue
    match '/ccavenue/:id/comeback'          => 'ccavenue#comeback', :as => :ccavenue_comeback
  end
end
