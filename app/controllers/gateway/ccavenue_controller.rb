require 'zlib'
class Gateway::CcavenueController < Spree::BaseController
  ssl_required :show
  include ERB::Util
  respond_to :html, :js
  skip_before_filter :verify_authenticity_token, :only => [:comeback]
  
  helper :simplified_json

  OUTWARD = [
               "Merchant_Id",
               "Amount",
               "Order_Id",
               "Redirect_Url"
              ]

  INWARD = [
    "Merchant_Id",
    "Order_Id",
    "Amount",
    "Auth_Desc",
    "Checksum"
  ]

  def show
    @order   = Order.find(params[:order_id])
    @gateway = @order.available_payment_methods.find{|x| x.id == params[:gateway_id].to_i }
    @order.payments.destroy_all
    payment = @order.payments.create!(:amount => 0,  :payment_method_id => @gateway.id)
    begin
      if !@order.ccavenue_successful_txn.nil?
        flash[:error] = I18n.t(:ccavenue_already_processed)
        redirect_to :back
        return
      end

      @order.ccavenue_pending_txns.each do |c|
        c.state = "failed"
      end
      
      new_txn = @order.ccavenue_infos.build(:state => 'new',
                                  :amount => @order.total,
                                  :order_number => @order.number)
      new_txn.generate_new_order_number!
      @order.save!
    rescue => e
      logger.error "Creating new order number for order id #{@order.id} failed"
      flash[:error] = "Internal error, you should never see this error!"
      redirect_to :back
      return
    end

    respond_to do |format|
      format.html do
        if @order.blank? || @gateway.blank?
          flash[:error] = I18n.t("invalid_arguments")
          redirect_to :back
        else
          @bill_address, @ship_address =  @order.bill_address, (@order.ship_address || @order.bill_address)
          render :action => :show
        end
      end
      format.js do
        if @order.blank? || @gateway.blank?
          render :json => { :error => I18n.t("invalid_arguments") }.to_json, :status => 500
        else
          @bill_address, @ship_address =  @order.bill_address, (@order.ship_address || @order.bill_address)
          render :show
        end
      end
    end
  end

  def comeback
    @order   = Order.find_by_number(params[:id])
    @gateway = @order && @order.payments.first.payment_method

    if @gateway && @gateway.kind_of?(PaymentMethod::Ccavenue) && params['AuthDesc'] && verify_checksum
      # Right now, there is no distinction between instant approval (Y) and batch approval (B)
      if params['AuthDesc'] == "Y" or params['AuthDesc'] == "B"
        logger.info "Order #{@order.number} authorized by CC Avenue. CC Avenue order no is #{params['nb_order_no']}"
        ccavenue_payment_success
        @order.next
        @order.save
        session[:order_id] = nil
        redirect_to order_url(@order, {:checkout_complete => true, :order_token => @order.token}), :notice => I18n.t("payment_success")
      elsif params['AuthDesc'] == "N"
        logger.info "Order #{@order.number} rejected by CC Avenue. Outputting params: #{params.inspect}"
        ccavenue_payment_rejected
        @order.save
        set_error_and_redirect(I18n.t("ccavenue_payment_rejected"))
      else
        logger.info "Order #{@order.number} failed at CC Avenue. Outputting params: #{params.inspect}"
        ccavenue_payment_failed
        set_error_and_redirect(I18n.t("ccavenue_payment_response_error"))
      end
    elsif !params['AuthDesc']
        logger.info "Order #{@order.number} canceled by user at CC Avenue. Outputting params: #{params.inspect}"
        ccavenue_payment_cancel
        set_error_and_redirect(I18n.t("ccavenue_payment_canceled"), :info)
    else
      logger.info "Order #{@order.number} failed at CC Avenue. Outputting params: #{params.inspect}"
      ccavenue_payment_failed
      set_error_and_redirect(I18n.t("ccavenue_payment_response_error"))
    end
  end

  private
  def set_error_and_redirect(error, notice_type=:error)
    flash[notice_type] = error
    if @order
      @order.save!
    end
    redirect_to (@order.blank? ? root_url : edit_order_url(@order))
  end

  def verify_checksum
    new_checksum = Zlib.adler32 params['Merchant_Id']+"|"+params['Order_Id']+"|"+params['Amount']+"|"+params['AuthDesc']+"|"+@gateway.preferred_working_key
    new_checksum.to_s == params['Checksum']
  end

  # Completed payment process
  #
  def ccavenue_payment_success
    last_txn = @order.ccavenue_latest_txn
    if last_txn.nil?
      logger.info "Order #{@order.number} has no transactions in 'new' state, but was asked to reject the latest new txn"
      # throw exception?
      return
    end

    last_txn.update_attributes(:amount_str => params['Amount'],
                                 :auth_desc => params['AuthDesc'],
                                 :checksum => params['Checksum'],
                                 :order_id => @order.id,
                                 :gateway_order_no => params['nb_order_no'],
                                 :card_category => params['card_category'],
                                 :state => 'success'
    )

    Payment.find_by_order_id(session[:order_id]).update_attributes(:source => last_txn, :payment_method_id => @gateway.id)
  end

  def ccavenue_payment_rejected
    last_txn = @order.ccavenue_latest_txn
    if last_txn.nil?
      logger.info "Order #{@order.number} has no transactions in 'new' state, but was asked to reject the latest new txn"
      return
    end

    last_txn.update_attributes(:amount_str => params['Amount'],
                                 :auth_desc => params['AuthDesc'],
                                 :checksum => params['Checksum'],
                                 :order_id => @order.id,
                                 :gateway_order_no => params['nb_order_no'],
                                 :card_category => params['card_category'],
                                 :state => 'rejected')
  end

  def ccavenue_payment_cancel
    last_txn = @order.ccavenue_latest_txn
    if last_txn.nil?
      logger.info "Order #{@order.number} has no transactions in 'new' state, but was asked to cancel the latest new txn"
      return
    end

    last_txn.update_attributes(:state => 'canceled')
  end

  def ccavenue_payment_failed
    last_txn = @order.ccavenue_latest_txn
    if last_txn.nil?
      logger.info "Order #{@order.number} has no transactions in 'new' state, but was asked to fail the latest new txn"
      return
    end

    last_txn.update_attributes(:state => 'failed')
  end
end
