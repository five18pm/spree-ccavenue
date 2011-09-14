class PaymentMethod::Ccavenue < PaymentMethod
  preference :account_id, :string
  preference :url,        :string, :default =>  "https://www.ccavenue.com/shopzone/cc_details.jsp"
  preference :working_key, :string
  preference :mode, :string

  def payment_profiles_supported?
    false
  end

  def external_gateway_based?
    true
  end

  def actions
    %w{capture void}
  end

  # Indicates whether its possible to capture the payment
  def can_capture?(payment)
    ['checkout', 'pending'].include?(payment.state)
  end

  # Indicates whether its possible to void the payment.
  def can_void?(payment)
    payment.state != 'void'
  end

  def capture(payment)
    payment.update_attribute(:state, 'pending') if payment.state == 'checkout'
    payment.complete
    true
  end

  def void(payment)
    payment.update_attribute(:state, 'pending') if payment.state == 'checkout'
    payment.void
    true
  end
end
