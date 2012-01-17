Spree::CheckoutController.class_eval do
  before_filter :ccavenue_redirect, :only => :update

  private
  def ccavenue_redirect
    return unless params[:state] == 'payment'
    @payment_method = Spree::PaymentMethod.find(params[:order][:payments_attributes].first[:payment_method_id])
    if @payment_method && @payment_method.kind_of?(Spree::Ccavenue::PaymentMethod)
      if @order.update_attributes(object_params)
        fire_event('spree.checkout.update')
        if @order.next
          redirect_to gateway_ccavenue_path(@order.number, @payment_method.id)
        else
          logger.error("Order transition failed for order #{@order.number}")
          raise Exception.new(:message => "Order transition failed")
        end
      end
    end
  end
end
