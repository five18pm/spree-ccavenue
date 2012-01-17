Spree::Order.class_eval do
  has_many :ccavenue_transactions, :class_name => 'Spree::Ccavenue::Transaction'

  def latest_ccavenue_transaction
    ccavenue_transactions.select{|txn| txn.sent? }.last
  end

  def has_authorized_ccavenue_transaction?
    !! ccavenue_transactions.select{|txn| txn.authorized? }.first
  end

  def cancel_existing_ccavenue_transactions!
    ccavenue_transactions.each{|t| t.cancel!}
  end
end
