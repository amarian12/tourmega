class User < ActiveRecord::Base
  DEFAULT_NAME = "TourMega Lovers"
  DEFAULT_AVATAR_URL = Figaro.env.DEFAULT_AVATAR_URL
  GENDERS = ["Male", "Female"]
  GUIDE_TYPE = [  :licensed_tour_company,
                  :licensed_local_guide,
                  :unlicensed_local_guide
                ]

  devise :database_authenticatable, :registerable, :recoverable, :async, :confirmable,
         :rememberable, :trackable, :validatable, :lockable, :omniauthable, :omniauth_providers => [:facebook, :twitter, :linkedin]

  include Private
  # extend FriendlyId
  # friendly_id :username, use: :slugged

  has_many :verifications, dependent: :destroy
  has_one :host, dependent: :destroy
  has_many :tours
  has_many :active_tours, -> { where(visible: true) }, foreign_key: 'user_id', class_name: "Tour"
  belongs_to :primary_address, class_name: 'Location', foreign_key: :primary_address_id, dependent: :destroy
  belongs_to :nationality, class_name: 'Country', foreign_key: :nationality_id
  has_many :reservations, dependent: :destroy
  has_many :bank_accounts, dependent: :destroy

  enum guide_type: GUIDE_TYPE
  accepts_nested_attributes_for :host

  mount_uploader :avatar, AvatarUploader
  mount_uploader :video_presentation, VideoUploader

  # validates :slug, presence: true, uniqueness: true
  validates :first_name, :last_name, presence: true

  class << self
    def collection
      select(:first_name, :last_name, :id).map{ |user| [user.first_name.to_s + ' ' + user.last_name.to_s, user.id] }
    end

    def from_omniauth(auth, user = nil, only_verified = false)
      unless only_verified
        email =
          case auth.provider
          when 'facebook'
            auth.info.email
          when 'twitter'
            auth.info.nickname.concat('@twitter.com')
          when 'linkedin'
            auth.info.email
          end
        user = find_by(email: email) || where(provider: auth.provider, uid: auth.uid).first_or_initialize
        user.email = email
        user.provider = auth.provider
        user.uid = auth.uid
        user.phone_number = auth.info.phone
        user.first_name = auth.info.name.split(' ')[0..-2].join(' ')
        user.last_name = auth.info.name.split(' ').last
        user.password = Devise.friendly_token[0, 20]
        user.remote_avatar_url = auth.info.image
        user.skip_confirmation! unless user.confirmed?
        user.save
      end
      user.verify_by_omniauth(auth)
      user
    end

    def import_from_external(user_json, provider)
      where(provider: provider, uid: user_json['id'].to_s).first_or_create do |user|
        user.email = "#{user_json['username']}@tournative.com"
        user.username = "#{provider}-#{user_json['username']}"
        user.first_name = user_json['full_name'].split(' ')[0..-2].join(' ')
        user.last_name = user_json['full_name'].split(' ').last
        user.remote_avatar_url = user_json['avatar']
        user.password = Devise.friendly_token[0, 20]
      end
      user = User.find_by(email: "#{user_json['username']}@tournative.com")

      filepath = "db/csv/#{Date.today.to_formatted_s(:number)}_users.csv"
      CSV.open(filepath, 'a+') do |csv|
        row = [ user.email, user.username, user.first_name, user.last_name, user.remote_avatar_url, user.provider, user.uid ]
        csv << row
      end
      user
    end
  end

  def verify_by_omniauth(auth)
    account_link = case auth.provider
    when 'twitter'
      auth.info.urls.Twitter
    when 'linkedin'
      auth.info.urls.public_profile
    else
      "http://facebook.com/#{uid}"
    end

    verification = verifications.where(source: auth.provider, account: account_link, verified: true).first_or_initialize
    verification.update message: "#{auth.provider.titleize}"
  end


  def name
    "#{first_name} #{last_name}".presence || email.presence || "Unidentifier"
  end

  def name_with_initial
    first_name + " #{last_name[0]}."
  end

  def is_a_host?
    host.present?
  end

  def own_tour?(tour_id)
    tours.find(tour_id).present?
  end

  def verified?
    verifications.where(source: Verification::SOURCES, verified: true).size == Verification::SOURCES.size
  end

  def partial_verified?
    verifications.where(source: Verification::SOURCES, verified: true).size >= 2
  end

  Verification::SOURCES.each do |source|
    define_method "#{source}_verified?" do
      verifications.find_by(source: source).try(:verified)
    end
  end

  Verification::SOURCES.each do |source|
    define_method "#{source}_verification" do
      verifications.find_by(source: source)
    end
  end

  def total_reviews
    tours.inject(0){ |sum, tour| sum + tour.no_of_reviews }
  end

  def all_reviews
    TourReview.where(tour_id: tour_ids)
  end

  def total_references
    BookingReference.where(referral_code: self.invite_code).count
  end

  def current_bank_account
    bank_accounts.order('created_at ASC').first
  end

  def after_confirmation
    UserMailer.welcome_message(self).deliver_later!(wait: 5.seconds)
    super
  end
end
