Spree::PaymentMethod.class_eval do
  has_many :ccavenue_transactions, :class_name => 'Spree::Ccavenue::Transaction'
end