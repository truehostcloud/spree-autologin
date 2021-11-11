class Spree::CustomUserAuthController < Spree::Api::V2::BaseController
  before_action -> { doorkeeper_authorize! :read, :admin }

  def auto_login
    payload = params[:custom_user_auth]

    email = payload[:email]

    raise ActionController::ParameterMissing.new(:email) if email.nil?

    user = Spree::User.find_by(email: email)

    raise ActiveRecord::RecordNotFound if user.nil?

    sign_in(user, event: :authentication)

    redirect_to spree.admin_path
  end
end
