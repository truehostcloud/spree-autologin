module Spree
  module Olitt
    class UsersController < Spree::Api::V2::BaseController
      def auto_login # rubocop:disable Metrics/AbcSize
        email, password, next_path = login_details
        user = Spree::User.find_by(email: email)
        vendor = ::Spree::Vendor.active.find_by(slug: email)

        vendor = create_vendor(email) if vendor_email_exist?(vendor)
        user = create_user(email, password, vendor.id) if user_email_exists?(user)
        raise CanCan::AccessDenied unless user.valid_password?(password)

        activate_vendor
        sign_in(user, event: :authentication)
        redirect_to next_path
      end

      private

      def login_details
        basic_auth = params[:basic_auth]
        next_path = params[:next] || spree.admin_path
        # backward compatibility for old api
        email = params[:email]
        password = params[:password]
        raise ActionController::ParameterMissing, :basic_auth if basic_auth.nil? && (email.nil? || password.nil?)
        if basic_auth
          auth_string = Base64.decode64(basic_auth)
          # convert auth_string to utf-8
          auth_string = auth_string.force_encoding('utf-8')
          email, password = auth_string.split(':')
        end

        raise ActionController::ParameterMissing, :email if email.nil?
        raise ActionController::ParameterMissing, :password if password.nil?

        [email, password, next_path]
      end

      def create_vendor(email)
        ::Spree::Vendor.create(name: email, notification_email: email)
      end

      def activate_vendor
        ::Spree::Vendor.update(state: 'active')
      end

      # this is a boolean method
      def vendor_email_exist?(vendor)
        vendor.nil?
      end

      # this is also a boolean method
      def user_email_exists?(user)
        user.nil?
      end

      def create_user(email, password, vendor_id)
        Spree::User.create(email: email, password: password, spree_role_ids: [2], vendor_ids: [vendor_id])
      end
    end
  end
end
