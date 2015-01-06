require 'khipu'
class Spree::Gateway::KhipuGateway < Spree::Gateway

  preference :commerce_id, :string
  preference :khipu_key, :string

  def provider
    Khipu.create_khipu_api(preferred_commerce_id, preferred_khipu_key)
  end

  def auto_capture?
    true
  end
  
  def source_required?
    false
  end
  
  def supports?(source)
    true
  end

  def provider_class
    ActiveMerchant::Billing::Integrations::Khipu
  end

  def method_type
    'khipu'
  end

  def authorize(money, creditcard, gateway_options)
    provider.authorize(money * 100, creditcard, gateway_options)
  end
end
