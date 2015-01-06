module Spree
  class KhipuPaymentReceipt < ActiveRecord::Base
    before_validation :extract_payment_info
    belongs_to :payment, foreign_key: 'transaction_id', primary_key: 'identifier' 
    
    private
    # Rellenar el receipt con la info del pago
    def extract_payment_info
    end
  end
end