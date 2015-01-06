module Spree
  require 'net/http'
  require 'net/https'
  require 'json'
  require 'khipu'
  class KhipuController < StoreController
    ssl_allowed
    protect_from_forgery except: [:notify]
    
    def pay
      order = current_order || raise(ActiveRecord::RecordNotFound)

      @payment = Spree::Payment.create(
        :amount => order.total,
        :order => order,
        :payment_method => payment_method
      )
      
      begin 
        map = provider.create_payment_url(payment_args(@payment))
        khipu_payment_url = map['url']
        redirect_to khipu_payment_url
        
      rescue Khipu::ApiError => error
        flash[:error] = 'Hubo un problema con Khipu, intente nuevamente más tarde.'
        redirect_to checkout_state_path(:payment) and return
      end
    end
    
    def success
      @payment = Spree::Payment.where(identifier: params[:payment]).last
      @khipu_receipt = Spree::KhipuPaymentReceipt.create(payment: @payment)
      
      @payment.order.next!
      redirect_to completion_route(@payment.order)
    end
    
    def cancel
      @payment = Spree::Payment.where(identifier: params[:payment]).last
      @khipu_receipt = Spree::KhipuPaymentReceipt.create(payment: @payment)
      
      redirect_to checkout_state_path(:payment) and return
    end
    
    def notify
      render nothing: true, status: :forbidden and return unless validate_payment(params)
      
      @payment = Spree::Payment.where(identifier: khipu_params[:transaction_id]).last
      
      render  nothing: true, status: :ok and return if @payment.order.payment_state == 'paid'
      
      @khipu_receipt = Spree::KhipuPaymentReceipt.where(transaction_id: @payment.identifier).last
      @khipu_receipt.update(khipu_params)
      @khipu_receipt.save!
      
      @payment.order.payment_state = 'paid'
      
      render  nothing: true, status: :ok
    end
    
    private
    
    def payment_args(payment)
      {
        receiver_id:    payment_method.preferences[:commerce_id],
        subject:        'Compra en REU Outdoor.',
        body:           "", 
        amount:         payment.amount.to_i,
        payer_email:    payment.order.email, 
        bank_id:        "", 
        expires_date:   "", 
        transaction_id: payment.identifier, 
        custom:         "", 
        notify_url:     khipu_notify_url, 
        return_url:     khipu_success_url(payment.identifier), 
        cancel_url:     khipu_cancel_url(payment.identifier), 
        picture_url:    "" # Rails.env.production? ? view_context.image_url('Logo Reu blanco.png') : ""
      }
    end
    
    def add_hash(args)
      args[:hash] = calculate_hash(args)
      args
    end
    
    def validate_payment(payment_args)
      begin 
        params = {
          api_version: payment_args[:api_version], 
          notification_id: payment_args[:notification_id], 
          subject: payment_args[:subject], 
          amount: payment_args[:amount],
          currency: payment_args[:currency], 
          transaction_id: payment_args[:transaction_id], 
          payer_email: payment_args[:payer_email],
          custom: payment_args[:custom], 
          notification_signature: payment_args[:notification_signature]
        }
        valid = provider.verify_payment_notification(params)
      rescue Khipu::ApiError => error
        puts error.type
        puts error.message
      end
    end
    
    def payment_method
      Spree::PaymentMethod.find(params[:payment_method_id]) || Spree::Payment.where(identifier: khipu_params[:transaction_id]).last.payment_method
    end
    
    def provider
      payment_method.provider
    end
    
    def khipu_params
        params.permit(:api_version, :receiver_id, :subject, :amount, :custom, :currency, :transaction_id, :notification_id, :payer_email)
    end
    
    def completion_route(order, custom_params = nil)
      spree.order_path(order, custom_params)
    end
  end
end
