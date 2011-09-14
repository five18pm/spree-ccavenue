CheckoutController.class_eval do

  before_filter :only => :update do
    redirect_for_ccavenue unless Spree::Config[:ccavenue_disable_redirect]
  end

  private

  def redirect_for_ccavenue
    return unless params[:state] == "payment"
    @payment_method = PaymentMethod.find(params[:order][:payments_attributes].first[:payment_method_id])
    if @payment_method && @payment_method.kind_of?(PaymentMethod::Ccavenue)
      @order.update_attributes(object_params)
      redirect_to gateway_ccavenue_path(:gateway_id => @payment_method.id, :order_id => @order.id)
    end
  end
end
