require 'factory_girl'

FactoryGirl.define do
  factory :ccavenue_payment_method, :class => Spree::Ccavenue::PaymentMethod do
    name 'CCAvenue'
    environment 'test'
    preferred_account_id 'M_ccavenuecust_12345'
    preferred_working_key '0987654321'
    preferred_mode 'test'
  end
end
