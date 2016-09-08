class UserMailer < ApplicationMailer
  default from: CEO_EMAIL

  def welcome_message(user)
    @user = user
    mail(to: user.email,
         subject: "Welcome to TourMega!",
         date: Time.now,
         template_path: 'mailers/user')
  end
end
