Spree CCavenue
==============

Spree CCAvenue is an extension for integrating Spree with the CCAvenue (http://www.ccavenue.com) payment gateway.

The extension by default redirects to the payment gateway at the payment step of the checkout process. If you are
 doing an one-page checkout you might want to redirect to the payment gateway only after all the checkout process
 is completed. In that case, you can disable the redirection through a Spree::Config setting. If you choose to 
 disable the redirection, you need to render/redirect to `ccavenue_path(gateway.id, order.id)` at some point of 
 time.

This extension is live in production at [SimpleLIFE.in](https://www.simplelife.in/)

Installation
============

1. Add to Gemfile:
        gem 'spree_ccavenue', :git => 'git://github.com/five18pm/spree_ccavenue.git'

2. run bundler
        bundle install

3. Install migration
        rake spree_ccavenue:install

4. Run migration
        rake db:migrate

5. Set whether you want to redirect to payment gateway or not
        In config/initializers/spree_ccavenue.rb (or any of the initialization files of your fancy):
          Spree::Config[:ccavenue_disable_redirect] = true

6. Create a payment method
        In Admin -> Configuration, click on Payment Methods.
        Add a new payment method, choose PaymentMethod::Ccavenue from the dropdown as the Provider.
        Provide your Account Id, Working key. You should get this from the CCAvenue website.
        Set the Work Mode to 'LIVE' or 'TEST' (Note that there is actually no 'TEST' mode at CCAvenue. 
        They just recommend to add 'Sub-merchant Test' in the order to indicate that this is a test transaction. 
        The 'TEST' mode does that.)

Example
=======
1. Normal checkout:
        No further changes are required apart from the installation. Once the payment step is reached,
        page gets redirected to confirmation page and then to CCAvenue payment page.

2. Redirect disabled:
        At some point of checkout process:
            Set @order.payment_method to an instance of PaymentMethod::Ccavenue.
            Render/Redirect to 'gateway_ccavenue_path(@order.payment_method.id, @order.id)'

            
Copyright (c) 2011 [five18pm](https://github.com/five18pm), released under the New BSD License
