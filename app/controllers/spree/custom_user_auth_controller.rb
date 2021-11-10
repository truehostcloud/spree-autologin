class Spree::CustomUserAuthController < ActionController::API
  # include Spree::Core::ControllerHelpers::Auth

  def create
    payload = params[:custom_user_auth]
    email = payload[:email]
    password = payload[:password]

    user = Spree::User.find_by(email: email)

    # get_last_access_token = ->(user) { Spree::OauthAccessToken.active_for(user).where(expires_in: nil).last }
    # create_access_token = ->(user) { Spree::OauthAccessToken.create!(resource_owner: user) }

    # user = get_last_access_token.call(user) || create_access_token.call(user)

    sign_in(user, event: :authentication)
    redirect_to spree.admin_path, notice: Spree.t(:account_updated)
    # render json: spree.account_path
    # render plain: defined?(spree)
  end
end
