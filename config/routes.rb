Spree::Core::Engine.routes.append do
  match "/gateway/:order_id/ccavenue/:payment_method_id" => 'ccavenue/gateway#show', :as => :gateway_ccavenue
  match "/gateway/ccavenue/:id/callback" => 'ccavenue/gateway#callback', :as => :gateway_ccavenue_callback
end
