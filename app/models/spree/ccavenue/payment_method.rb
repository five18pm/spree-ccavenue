class Spree::Ccavenue::PaymentMethod < Spree::PaymentMethod
  preference :account_id,  :string
  preference :url,         :string, :default =>  "https://www.ccavenue.com/shopzone/cc_details.jsp"
  preference :working_key, :string
  preference :mode,        :string
  preference :batch_transaction_should_complete_order, :boolean, :default => true

  def payment_profiles_supported?
    true # we want to show the confirm step.
  end

  def provider_class
    Spree::Ccavenue::Transaction
  end

  def payment_source_class
    Spree::Ccavenue::Transaction
  end

  def method_type
    'ccavenue'
  end
end
