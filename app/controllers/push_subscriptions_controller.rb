class PushSubscriptionsController < ApplicationController
  skip_before_action :check_trial_restrictions!

  def create
    sub = current_user.push_subscriptions.find_or_initialize_by(endpoint: params[:endpoint])
    sub.p256dh_key = params.dig(:keys, :p256dh)
    sub.auth_key   = params.dig(:keys, :auth)
    sub.save!
    head :ok
  rescue ActiveRecord::RecordInvalid
    head :unprocessable_entity
  end

  def destroy
    current_user.push_subscriptions.find_by(endpoint: params[:endpoint])&.destroy
    head :ok
  end
end
