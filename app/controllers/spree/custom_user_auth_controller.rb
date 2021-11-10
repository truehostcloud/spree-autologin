class Spree::CustomUserAuthController < Spree::Api::BaseController
  def auto_login
    payload = params[:custom_user_auth]

    email = payload[:email]
    password = payload[:password]

    user = Spree::User.find_by(email: email)

    if user.nil?
      not_found
      return
    end

    sign_in(user, event: :authentication)

    redirect_to spree.admin_path
  end
end
