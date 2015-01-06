module Spree
  module ViewHelpers
    def calculate_hash(hash)
      key = 'e5e0e9502c49260803ac508c5f422e9c3e19fe5b'
      concat = hash.map{|k,v| "#{k}=#{v}"}.join('&')
      Digest::HMAC.hexdigest(concat, key, Digest::SHA256)
    end
  end
end