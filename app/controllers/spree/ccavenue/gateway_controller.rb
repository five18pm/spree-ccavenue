class Spree::Ccavenue::GatewayController < Spree::BaseController
  ssl_required :show
  helper "spree/checkout"
  def show
    @order = Spree::Order.find_by_number(params[:order_id])
    if !@order
      flash[:error] = "Unknown order"
      render :error
      return
    end

    @payment_method = Spree::PaymentMethod.find(params[:payment_method_id])
    if !@payment_method or !@payment_method.kind_of?(Spree::Ccavenue::PaymentMethod)
      flash[:error] = "Invalid payment method for this transaction"
      render :error
      return
    end

    if @order.has_authorized_ccavenue_transaction?
      flash[:error] = "Order #{@order.number} is already authorized at CCAvenue"
      render :error
      return
    end

    @order.cancel_existing_ccavenue_transactions!
    @order.payments.destroy_all
    @order.payments.build(:amount => @order.total, :payment_method_id => @payment_method.id)
    @transaction = @order.ccavenue_transactions.build(:amount => @order.total,
                                                    :payment_method_id => @payment_method.id)

    @transaction.transact
    @order.save!
    logger.info("Sending order #{@order.number} to CCAvenue via transaction id #{@transaction.id}")
    @bill_address, @ship_address = @order.bill_address, (@order.ship_address || @order.bill_address)
  end

  def callback
    @transaction = Spree::Ccavenue::Transaction.find(params[:id])
    if !@transaction
      # raise error
    end

    logger.info "Received transaction from CCAvenue #{params.inspect}"

    @transaction.auth_desc = params['AuthDesc']
    @transaction.checksum = params['Checksum']
    @transaction.card_category = params['card_category']
    @transaction.ccavenue_order_number = params['nb_order_no']
    @transaction.ccavenue_amount = params['Amount']

    session[:access_token] = @transaction.order.token if @transaction.order.respond_to?(:token)
    session[:order_id] = @transaction.order.id

    if @transaction.next
      if @transaction.authorized? or (@transaction.batch? and @transaction.order.complete?)
        session[:order_id] = nil
        flash.notice = I18n.t(:order_processed_successfully)
        flash[:commerce_tracking] = "nothing special"
        # We are setting token here so that even if the URL is copied and reused later on
        # the completed order page still gets displayed
        if session[:access_token].nil?
          redirect_to spree.order_path(@transaction.order, { :checkout_complete => true })
        else
          redirect_to spree.order_path(@transaction.order, { :checkout_complete => true, :token => session[:access_token] })
        end
      elsif @transaction.rejected?
        redirect_to spree.edit_order_path(@transaction.order), :error => I18n.t("payment_rejected")
      elsif @transaction.canceled?
        redirect_to spree.edit_order_path(@transaction.order), :notice => I18n.t("payment_canceled")
      elsif @transaction.batch?
        # Don't allow the order to be reused.
        session[:order_id] = nil
        render 'batch'
      elsif @transaction.error_state?
        flash[:error] = I18n.t(:ccavenue_invalid_transaction)
        redirect_to spree.edit_order_path(@transaction.order)
      end
    else
      render 'error'
    end
  end
end
