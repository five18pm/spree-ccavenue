require 'spec_helper'

describe Spree::Ccavenue::Transaction do
  context "associations" do
    it { should belong_to(:order) }
    it { should belong_to(:payment_method) }
  end

  context "states" do
    after(:each) do
      Spree::PaymentMethod.all.each do |pm|
        pm.clear_preferences
      end
    end

    it "should start at created state" do
      transaction = Spree::Ccavenue::Transaction.new
      transaction.state.should == 'created'
    end

    it "should move state to sent" do
      transaction = Factory(:ccavenue_transaction)
      transaction.transact
      transaction.state.should == 'sent'
    end

    it "should raise exception if order is not in confirm state" do
      transaction = Factory(:ccavenue_transaction)
      transaction.order.state = 'payment'
      expect { transaction.transact }.to raise_error
      transaction.state.should == 'created'
    end

    it "should create a transaction number before transacting" do
      transaction = Factory(:ccavenue_transaction)
      transaction.transact
      transaction.transaction_number.should_not be_nil
      transaction.gateway_order_number.should_not be_nil
    end

    it "should move to 'invalid' state when transaction checksum do not match" do
      transaction = Factory(:ccavenue_sent_transaction)
      transaction.auth_desc = 'Y'
      transaction.checksum = "123456789"
      transaction.next
      transaction.state.should == 'error_state'
    end

    it "should complete order when state is authorized" do
      transaction = Factory(:ccavenue_sent_transaction)
      transaction.auth_desc = 'Y'
      transaction.checksum = transaction.generate_checksum
      transaction.next
      transaction.state.should == 'authorized'
      transaction.order.state.should == 'complete'
    end

    it "should move to rejected when proceeding to next state for a rejected transaction" do
      transaction = Factory(:ccavenue_sent_transaction)
      transaction.auth_desc = 'N'
      transaction.checksum = transaction.generate_checksum
      transaction.next
      transaction.state.should == 'rejected'
    end

    it "should keep the order at same state when transaction state is rejected" do
      transaction = Factory(:ccavenue_sent_transaction)
      current_state = transaction.order.state
      transaction.auth_desc = 'N'
      transaction.checksum = transaction.generate_checksum
      transaction.next
      transaction.order.state.should == current_state
    end

    it "should move to batch when proceeding to next state for a batch transaction and should complete order" do
      transaction = Factory(:ccavenue_sent_transaction)
      transaction.auth_desc = 'B'
      transaction.checksum = transaction.generate_checksum
      transaction.next
      transaction.state.should == 'batch'
      transaction.order.state.should == 'complete'
    end

    it "should not complete order when state is batch and batch should complete order" do
      transaction = Factory(:ccavenue_batch_transaction)
      transaction.payment_method.set_preference(:batch_transaction_should_complete_order, false)
      transaction.checksum = transaction.generate_checksum
      transaction.save!
      transaction.next
      transaction.order.state.should_not == 'complete'
    end

    it "should cancel the transaction when there is no authorization info (auth_desc is nil)" do
      transaction = Factory(:ccavenue_sent_transaction)
      transaction.transact
      transaction.next
      transaction.state.should == 'canceled'
    end

    it "should cancel transaction from any state other than authorized when cancel event is triggered" do
      transaction = Factory(:ccavenue_transaction)
      transaction.cancel
      transaction.state.should == 'canceled'

      transaction = Factory(:ccavenue_transaction)
      transaction.transact
      transaction.cancel
      transaction.state.should == 'canceled'

      transaction = Factory(:ccavenue_rejected_transaction)
      transaction.cancel
      transaction.state.should == 'canceled'

      transaction = Factory(:ccavenue_batch_transaction)
      transaction.cancel
      transaction.state.should == 'canceled'

      transaction = Factory(:ccavenue_authorized_transaction)
      transaction.cancel
      transaction.state.should == 'authorized'
    end
  end
end
