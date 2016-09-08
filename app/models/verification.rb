class Verification < ActiveRecord::Base
  SOURCES = [
    'phone_number',
    'facebook',
    'twitter',
    'linkedin'
  ]
  SOCIAL_SOURCES= [
    'facebook',
    'twitter',
    'linkedin'
  ]

  belongs_to :user
  validates :source, :account, presence: true

  def formated_string
    status = verified ? "Yes" : "No"
    "#{source}: #{account} - #{status}"
  end

  def verify!
    update_attributes(verified: true)
  end
end
