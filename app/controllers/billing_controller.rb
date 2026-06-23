class BillingController < ApplicationController
  def new
  end

  def create_checkout
    price_id = params[:plan] == "annual" \
      ? ENV["STRIPE_PRICE_ANNUAL"] \
      : ENV["STRIPE_PRICE_MONTHLY"]

    session = Stripe::Checkout::Session.create(
      customer_email: current_user.email,
      mode:           "subscription",
      line_items:     [{ price: price_id, quantity: 1 }],
      success_url:    billing_success_url,
      cancel_url:     billing_cancel_url,
      metadata:       { user_id: current_user.id }
    )

    redirect_to session.url, allow_other_host: true
  rescue Stripe::StripeError => e
    Rails.logger.error "[Billing] Stripe error: #{e.message}"
    redirect_to billing_new_path, alert: "Erro ao iniciar pagamento. Tente novamente."
  end

  def success
  end

  def cancel
  end
end
