module Spree
  module Olitt
    class UsersController < Spree::Api::V2::BaseController
      def auto_login
        email, password = login_details

        user = Spree::User.find_by(email: email)

        user = create_user(email, password) if user.nil?

        raise ActiveRecord::RecordNotFound if user.nil?

        raise CanCan::AccessDenied unless user.valid_password?(password)

        sign_in(user, event: :authentication)

        redirect_to spree.admin_path
      end

      private

      def login_details
        email = params[:email]
        password = params[:password]

        raise ActionController::ParameterMissing, :email if email.nil?
        raise ActionController::ParameterMissing, :password if password.nil?

        [email, password]
      end

      def create_user(email, password)
        Spree::User.create(email: email, password: password, spree_role_ids: [1])
      end
    end
  end
end
