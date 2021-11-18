module Spree
  module Olitt
    class UsersController < Spree::Api::V2::BaseController
      def auto_login # rubocop:disable Metrics/AbcSize
        email, name = login_details
        # user = Spree::User.find_by(email: email)
        vendor = ::Spree::Vendor.active.find_by(slug: name)

        vendor = create_vendor(name, email) if vendor_email_exist?(vendor)
        Rails.logger.error(vendor)
        # user = create_user(email, password, vendor.id) if user_email_exists?(user)

        # raise CanCan::AccessDenied unless user.valid_password?(password)

        # create_vendor_user(vendor.id, 4)
        # sign_in(user, event: :authentication)
        # redirect_to spree.admin_path
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

      def create_vendor(name, email)
        ::Spree::Vendor.create(name: name, notification_email: email)
      end

      # this is a boolean method 🤪
      def vendor_email_exist?(vendor)
        vendor.nil?
      end

      # this is also a boolean method 🤪
      def user_email_exists?(user)
        user.nil?
      end

      def create_user(email, password)
        Spree::User.create(email: email, password: password, spree_role_ids: [2])
      end

      def create_vendor_user(vendor_id, _user_id)
        ::Spree::VendorUser.create(vendor_id: vendor_id, user_id: user_id)
      end
    end
  end
end
