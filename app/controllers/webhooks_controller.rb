class WebhooksController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token
  skip_before_action :check_trial_restrictions!

  def stripe
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, ENV["STRIPE_WEBHOOK_SECRET"]
      )
    rescue JSON::ParserError, Stripe::SignatureVerificationError => e
      Rails.logger.error "[Webhook] Invalid: #{e.message}"
      return head :bad_request
    end

    case event["type"]
    when "checkout.session.completed"
      handle_checkout_completed(event["data"]["object"])
    when "invoice.payment_succeeded"
      handle_payment_succeeded(event["data"]["object"])
    when "invoice.payment_failed"
      handle_payment_failed(event["data"]["object"])
    when "customer.subscription.deleted"
      handle_subscription_deleted(event["data"]["object"])
    end

    head :ok
  end

  private

  def handle_checkout_completed(session)
    user = User.find_by(id: session.dig("metadata", "user_id"))
    return unless user

    subscription = Stripe::Subscription.retrieve(session["subscription"])

    user.update!(
      role:                         "student",
      stripe_customer_id:           session["customer"],
      stripe_subscription_id:       session["subscription"],
      subscription_status:          "active",
      subscription_current_period_end: Time.at(subscription["current_period_end"]).utc
    )
    Rails.logger.info "[Webhook] ✅ Aluno #{user.email} ativou assinatura"
  end

  def handle_payment_succeeded(invoice)
    user = User.find_by(stripe_customer_id: invoice["customer"])
    return unless user

    if invoice["subscription"].present?
      subscription = Stripe::Subscription.retrieve(invoice["subscription"])
      user.update!(
        subscription_status:             "active",
        subscription_current_period_end: Time.at(subscription["current_period_end"]).utc
      )
    end
  end

  def handle_payment_failed(invoice)
    user = User.find_by(stripe_customer_id: invoice["customer"])
    return unless user

    user.update!(subscription_status: "past_due")
    Rails.logger.warn "[Webhook] ⚠️ Falha de pagamento: #{user.email}"
  end

  def handle_subscription_deleted(subscription)
    user = User.find_by(stripe_subscription_id: subscription["id"])
    return unless user

    user.update!(
      role:                "trial",
      subscription_status: "canceled"
    )
    Rails.logger.info "[Webhook] ❌ Assinatura cancelada: #{user.email}"
  end
end
