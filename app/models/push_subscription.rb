class PushSubscription < ApplicationRecord
  belongs_to :user
  validates :endpoint, presence: true, uniqueness: { scope: :user_id }
end
