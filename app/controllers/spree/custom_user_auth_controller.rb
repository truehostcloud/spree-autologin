class Spree::CustomUserAuthController < ActionController::API
  def create
    payload = params[:custom_user_auth]

    email = payload[:email]
    password = payload[:password]

    user = Spree::User.find_by(email: email)

    if user === nil
      render json: {error: Spree.t(:authorization_failure)}
      return
    end

    sign_in(user, event: :authentication)

    redirect_to spree.admin_path
  end
end
