class User < ApplicationRecord
  # Team 0 = admin
  # Team 1-8 = red, blue, yellow, green, purple, orange, black, white

  before_save
  validates :username, presence: true, length: {maximum: 50}
  validates :team, presence: true

  has_secure_password
end
