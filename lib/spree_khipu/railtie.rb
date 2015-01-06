require 'spree_khipu/view_helpers'
module SpreeKhipu
  class Railtie < Rails::Railtie
    initializer "spree_khipu.view_helpers" do
      ActionView::Base.send :include, Spree::ViewHelpers
    end
  end
end