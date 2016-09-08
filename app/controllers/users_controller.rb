class UsersController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :authenticate_user!, only: [:public_profile]
  before_action :fetch_reservations, only: [:reservations]
  before_action :fetch_travels, only: [:travels]
  before_action :fetch_crafted_tours, only: [:crafted_tours]
  before_action :get_public_user_tours, only: [:public_profile]
  before_action :set_bank_account, only: [:bank_accounts]
  before_action :set_location, only: [:update]
  before_action :set_column_navigation, only: [:reservations, :travels, :references, :verifications, :crafted_tours, :account_settings, :profile_information, :availability, :bank_accounts]

  def public_profile
    @reviews = TourReview.for_user(@user.id)
    respond_to do |format|
      format.html
      format.js
    end
  end

  def crafted_tours; end
  def reservations; end
  def travels; end
  def verifications; end
  def account_settings; end
  def profile_information; end
  def availability; end
  def references; end
  def bank_accounts; end

  def index
    @column = 'profile'

    respond_to do |format|
      format.html
      format.js { render 'content.js' }
    end
  end

  def update
    @column = 'profile'
    flash.now[:notice] = "Update profile successfully" if current_user.update(@users_attributes)

    respond_to do |format|
      format.html { redirect_to users_path }
      format.js { render 'content.js' }
    end
  end

  def host
    @host = current_user.host || current_user.build_host
  end

  def twilio_send_message
    destroy_last_current_phone_number_verifications
    current_user.update(user_params)
    phone_verification = current_user.verifications.create(source: 'phone_number', account: user_params[:phone_number], verified: false, message: generate_token)
    twilio_number = ENV['TWILIO_NUMBER']
    @client = Twilio::REST::Client.new ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN']
    message = @client.account.messages.create(
      :from => twilio_number,
      :to => user_params[:phone_number],
      :body => "Your verification code is #{@token}"
    )
    puts message.to

    respond_to do |format|
      format.js { render 'users/verifications/twilio.js'}
    end
  end

  def twilio_verify
    if current_user.phone_number_verification.message == params[:verification_code]
      current_user.phone_number_verification.verify!

      render json: {success: true}, status: :ok
    else
      render json: {success: false}, status: :ok
    end
  end

  private

  def generate_token
    @token = rand(0000..999999).to_s.rjust(4, "0")
  end

  def destroy_last_current_phone_number_verifications
    current_user.verifications.where(source: 'phone_number').destroy_all
  end

  def set_column_navigation
    @column = action_name
    respond_to do |format|
      format.html { render 'index.html' }
      format.js { render 'content.js' }
    end
  end

  def user_params
    params.require(:user).permit(:video_presentation, :gender, :phone_number, :phone, :job_title, :biography, :date_of_birth, :hobbies, :guide_type, :nationality_id, :primary_address_id, :primary_address, :email, :first_name, :last_name, :avatar, languages: [])
  end

  def fetch_reservations
    if params[:status] == 'confirmed'
      @reservations = current_user.reservations.completed
    else
      @reservations = current_user.reservations.pending
    end
    @reservations.includes(:tour)
  end

  def fetch_travels
    @reservations = current_user.reservations.completed
    @travels = @reservations.for_tours
  end

  def fetch_crafted_tours
    @tours = current_user.tours.page(params[:page]).per(6)
  end

  def get_public_user_tours
    @user = User.find(params[:id])
    # TODO: handle paginate properly
    @tours = @user.tours.page(params[:page]).per(10)
  end

  def set_bank_account
    @bank_account = current_user.current_bank_account || current_user.bank_accounts.new
  end

  def location_params
    user_params[:primary_address] && params[:locate_primary_address].present? ? eval(user_params.require(:primary_address)) : nil
  end

  def set_location
    @location = Location.first_or_create(location_params) if location_params
    @users_attributes = user_params.except(:primary_address).merge(primary_address: @location)
  end
end