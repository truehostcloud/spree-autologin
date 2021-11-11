module Spree
  module Olitt
    class UsersController < Spree::Api::V2::BaseController
      def auto_login
        email = params[:email]
        password = params[:password]

        raise ActionController::ParameterMissing, :email if email.nil?
        raise ActionController::ParameterMissing, :password if password.nil?

        user = Spree::User.find_by(email: email)

        user = create_user(email, password) if user.nil?

        raise ActiveRecord::RecordNotFound if user.nil?

        if user.valid_password?(password)
          sign_in(user, event: :authentication)
          redirect_to spree.admin_path
        else
          raise CanCan::AccessDenied
        end
      end

      private

      def create_user(email, password)
        Spree::User.create(email: email, password: password, spree_role_ids: [1])
      end
    end
  end
end
