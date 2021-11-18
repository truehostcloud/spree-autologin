module Spree
  module Olitt
    class UsersController < Spree::Api::V2::BaseController
      def auto_login
        email, password, name = login_details

        new_vendor = create_vendor(name, email, password) if vendor_email_exist(emial)

        user = create_user(email, password, new_vendor.id) if user_email_exists

        raise CanCan::AccessDenied unless user.valid_password?(password)

        sign_in(user, event: :authentication)

        redirect_to spree.admin_path
      end

      private

      def login_details
        email = params[:email]
        password = params[:password]
        name = params[:name]

        raise ActionController::ParameterMissing, :email if email.nil?
        raise ActionController::ParameterMissing, :password if password.nil?
        raise ActionController::ParameterMissing, :name if name.nil?

        [email, password, name]
      end

      def create_vendor(name, email, password)
        Spree::Api::V1::VendorsController.create(name: name, email: email, password: password)
      end

      # this is a boolean method 🤪
      def vendor_email_exist?(email)
        vendor = Spree::Api::V1::VendorsController.find_by(email: email)
        vendor.nil?
      end

      # this is also a boolean method 🤪
      def user_email_exists?(email)
        user = Spree::User.find_by(email: email)
        user.nil?
      end

      def create_user(email, password, vendor_id)
        Spree::User.create(email: email, password: password, spree_role_ids: [2], spree_vendor_id: vendor_id)
      end
    end
  end
end
