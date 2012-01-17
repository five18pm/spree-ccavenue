require 'spec_helper'

describe Spree::Ccavenue::GatewayController do
  before(:all) do
    @payment_method = Factory(:ccavenue_payment_method)
  end

  after(:all) do
    Spree::Ccavenue::PaymentMethod.destroy_all
  end

  it "should have Spree::Ccavenue::PaymentMethod as an available payment method" do
    Spree::PaymentMethod.available.select{|pm| pm.class == Spree::Ccavenue::PaymentMethod}.count.should == 1
  end

  context "show" do
    before do
      @order = Factory(:order)
    end

    it "raise error when order is not found" do
      get :show, { :order_id => "R98762311", :payment_method_id => @payment_method.id, :use_route => :spree }
      flash[:error].should_not be_nil
    end

    it "raise error if there is already an existing authorized transaction" do
      @order.state = "confirm"
      t = Factory(:ccavenue_authorized_transaction)
      t.order = @order
      t.save!
      @order.ccavenue_transactions.reload
      @order.save!
      get :show, { :order_id => @order.number, :payment_method_id => @payment_method.id, :use_route => :spree }
      flash[:error].should_not be_nil
    end

    it "raise error if the payment method is not Spree::Ccavenue::PaymentMethod" do
      @order.state = "confirm"
      @order.payments.create!(:payment_method_id => @payment_method.id, :amount => @order.total)
      pm = Spree::PaymentMethod::Check.create!
      get :show, { :order_id => @order.number, :payment_method_id => pm.id, :use_route => :spree }
      flash[:error].should_not be_nil
    end

    it "cancel existing ccavenue payments" do
      @order.state = "confirm"
      @order.payments.create!(:payment_method_id => @payment_method.id, :amount => @order.total)
      t = Factory(:ccavenue_transaction)
      t.order = @order
      t.transact
      t.save!
      t = Factory(:ccavenue_transaction)
      t.order = @order
      t.transact
      t.save!
      @order.save!

      @order.ccavenue_transactions.reload
      get :show, { :order_id => @order.number, :payment_method_id => @payment_method.id, :use_route => :spree }
      @order.ccavenue_transactions.reload
      @order.ccavenue_transactions.size.should == 3
      @order.ccavenue_transactions.select{|ct| ct.canceled? }.size.should == 2
      @order.ccavenue_transactions.select{|ct| ct.sent? }.size.should == 1
    end
  end

  context 'callback' do
    before(:each) do
      @order = Factory(:order_with_totals)
      @order.state = 'confirm'
      @order.payments.create!(:payment_method_id => @payment_method.id, :amount => @order.total)
      @order.save!
      @transaction = @order.ccavenue_transactions.create!(:payment_method_id => @payment_method.id, :amount => @order.total)
      @transaction.transact
      @order.save!
    end

    it "should complete order" do
      post :callback, ccavenue_params('Y')
      response.should redirect_to(spree.order_path(@order, {:checkout_complete => true}))
    end

    it "should fail order and redirect to cart page" do
      post :callback, ccavenue_params('N')
      response.should redirect_to(spree.edit_order_path(@order))
    end

    it "should complete order when transaction is batch processed" do
      post :callback, ccavenue_params('B')
      response.should redirect_to(spree.order_path(@order, {:checkout_complete => true}))
    end

    it "should cancel order when auth_desc is nil" do
      post :callback, {:use_route => :spree, :id => @transaction.id}
      response.should redirect_to(spree.edit_order_path(@order))
    end

    it "should redirect to edit order page when transaction is in invalid state" do
      params = ccavenue_params('Y')
      params['Checksum'] = 'ABCD'
      post :callback, params
      response.should redirect_to(spree.edit_order_path(@order))
    end
  end
end

def checksum(*args)
  Zlib.adler32(args.join("|")).to_s
end

def ccavenue_params(auth_desc)
  params = {}
  params['AuthDesc'] = auth_desc
  params['nb_order_no'] = 'CCAV123456'
  params['Amount'] = @order.amount.to_s
  params['Checksum'] = checksum(@payment_method.preferred_account_id, 
                                @transaction.gateway_order_number, 
                                params['Amount'], 
                                params['AuthDesc'],
                                @payment_method.preferred_working_key)
  params['card_category'] = 'NETBANKING'
  params[:use_route] = :spree
  params[:id] = @transaction.id
  params
end
