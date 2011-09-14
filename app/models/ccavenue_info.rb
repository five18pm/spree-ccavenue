class CcavenueInfo < ActiveRecord::Base
  belongs_to :order
  validates_presence_of :ccavenue_order_number
  validates_presence_of :order_number

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
  end

  def void(payment)
    payment.update_attribute(:state, 'pending') if payment.state == 'checkout'
    payment.void
  end

  def generate_new_order_number!
    record = true
    while record
      random = "#{Array.new(4){rand(4)}.join}"
      record = self.class.find(:first, :conditions => ["ccavenue_order_number = ? and order_number = ?", random, self.order_number])
    end
    self.ccavenue_order_number = random
    self.ccavenue_order_number
  end

  def remote_order_number
    self.order_number + self.ccavenue_order_number
  end
end
