require 'zlib'

module CheckoutHelper
  def get_checksum(merchant_id, order_id, amount, redirect_url, working_key)
    Zlib.adler32(merchant_id+"|"+order_id+"|"+amount+"|"+redirect_url+"|"+working_key)
  end
end
