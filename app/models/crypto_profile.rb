class CryptoProfile < ApplicationRecord
  belongs_to :user, optional: true

  validates :ethereum_address, length: { maximum: 42 }
end
