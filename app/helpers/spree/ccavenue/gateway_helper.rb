module Spree::Ccavenue::GatewayHelper
  def transaction_checksum(*args)
    Zlib.adler32(args.join('|')).to_s
  end
end
