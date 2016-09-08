class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  ['facebook', 'twitter', 'linkedin'].each do |social|
    define_method "#{social}" do
      if is_only_verified?
        @user = User.from_omniauth(request.env["omniauth.auth"], current_user, is_only_verified?)
      else
        @user = User.from_omniauth(request.env["omniauth.auth"])
      end

      if @user.persisted?
        if is_only_verified?
          redirect_to send(referrer_path), notice: "You are verified via #{social.titleize}"
        else
          sign_in_and_redirect @user, :event => :authentication
          set_flash_message(:notice, :success, :kind => "#{social.titleize}") if is_navigational_format?
        end
      else
        if is_only_verified?
          redirect_to send(referrer_path), error: 'Cannot be verified via #{social.titleize}'
        else
          session["devise.#{social}_data"] = request.env["omniauth.auth"]
          flash[:alert] = "Cannot sign in with your #{social.titleize}"
          redirect_to new_user_registration_url
        end
      end
    end
  end

  private

  def extra_params
    request.env['omniauth.params']
  end

  def is_only_verified?
    extra_params['only_verified']
  end

  def referrer_path
    "#{extra_params['referrer_column'].presence || 'profile'}_users_path"
  end
end
