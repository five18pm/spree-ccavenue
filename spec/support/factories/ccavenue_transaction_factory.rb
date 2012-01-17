require 'factory_girl'

FactoryGirl.define do
  factory :ccavenue_transaction, :class => Spree::Ccavenue::Transaction do
    order { Factory(:order) }
    payment_method { Factory(:ccavenue_payment_method) }
    amount {|t| t.order.amount }
    after_create do |txn, proxy|
      payment = Spree::Payment.new(:order => txn.order)
      txn.order.payments = []
      txn.order.payments << payment
      txn.order.state = 'confirm'
      txn.save!
    end
  end

  factory :ccavenue_sent_transaction, :parent => :ccavenue_transaction do
    transaction_number '1234'
    state 'sent'
    ccavenue_amount {|t| t.order.amount.to_s}
    after_create do |txn, proxy|
      txn.checksum = txn.generate_checksum
    end
  end

  factory :ccavenue_rejected_transaction, :parent => :ccavenue_sent_transaction do
    state 'rejected'
    auth_desc 'N'
  end

  factory :ccavenue_authorized_transaction, :parent => :ccavenue_sent_transaction do
    state 'authorized'
    auth_desc 'Y'
  end

  factory :ccavenue_batch_transaction, :parent => :ccavenue_sent_transaction do
    state 'batch'
    auth_desc 'B'
  end
end
