class Spree::Ccavenue::Transaction < ActiveRecord::Base
  belongs_to :order, :class_name => 'Spree::Order'
  belongs_to :payment_method, :class_name => 'Spree::Ccavenue::PaymentMethod'
  has_many :payments, :as => :source

  def actions
    %w{capture void}
  end

  def can_capture?(payment)
    ['checkout', 'pending'].include?(payment.state)
  end

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

  state_machine :initial => :created, :use_transactions => false do
    before_transition :to => :sent, :do => :initialize_state!
    event :transact do
      transition :created => :sent
    end

    event :next do
      transition :sent => :canceled, :if => lambda {|txn| txn.auth_desc.nil? }
      transition :sent => :error_state, :if => lambda {|txn| !txn.verify_checksum }
      transition [:sent, :batch] => :authorized, :if => lambda {|txn| txn.auth_desc == 'Y' && txn.verify_checksum }
      transition [:sent, :batch] => :rejected, :if => lambda {|txn| txn.auth_desc == 'N' && txn.verify_checksum }
      transition :sent => :batch, :if => lambda {|txn| txn.auth_desc == 'B' && txn.verify_checksum }
    end
    after_transition :to => :authorized, :do => :payment_authorized
    after_transition :to => :batch do |txn|
      txn.payment_authorized if txn.payment_method.preferred_batch_transaction_should_complete_order
    end

    event :cancel do
      transition all - [:authorized] => :canceled
    end
  end

  def generate_checksum
    Zlib.adler32([self.payment_method.preferred_account_id,
                  gateway_order_number,
                  ccavenue_amount,
                  auth_desc,
                  self.payment_method.preferred_working_key].join('|')).to_s
  end

  def verify_checksum
    generate_checksum == self.checksum
  end

  def payment_authorized
    order.payment.update_attributes :source => self, :payment_method_id => self.payment_method.id
    order.next
    order.save
  end

  def initialize_state!
    raise "Order is not in 'confirm' state. Order should be in 'confirm' state before transaction can be sent to CCAvenue" unless order.confirm?
    this = self
    previous = order.ccavenue_transactions.reject{|t| t == this}
    previous.each {|p| p.cancel!}
    generate_transaction_number!
  end

  def gateway_order_number
    order.number + transaction_number
  end

  def generate_transaction_number!
    record = true
    while record
      random = "#{Array.new(4){rand(4)}.join}"
      record = self.class.find(:first, :conditions => ["transaction_number = ? and order_id = ?", random, self.order.id])
    end
    self.transaction_number = random
  end

  def initialize(*args)
    if !args or args.empty?
      super(*args)
    else
      from_admin = args[0].delete('from_admin')
      super(*args)
      if from_admin
        self.amount = self.order.amount
        self.transact
        self.ccavenue_amount = self.amount.to_s
        self.checksum = generate_checksum
        self.next
      end
    end
  end
end
