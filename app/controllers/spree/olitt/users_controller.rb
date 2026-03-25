require 'base64'
require 'uri'

module Spree
  module Olitt
    class UsersController < Spree::BaseController
      def auto_login
        email, password, next_path = login_details

        user = nil
        vendor = nil

        Spree.user_class.transaction do
          vendor = find_or_create_vendor(email)
          user = find_or_create_user(email, password)

          raise CanCan::AccessDenied unless user.valid_password?(password)

          assign_vendor_role(user, vendor)
          activate_vendor(vendor)
        end

        sign_in(user, event: :authentication)
        redirect_to next_path, allow_other_host: false
      end

      private

      def login_details
        basic_auth = params[:basic_auth]
        next_path = sanitize_next_path(params[:next]) || spree.admin_dashboard_path
        email = params[:email]
        password = params[:password]

        raise ActionController::ParameterMissing, :basic_auth if basic_auth.nil? && (email.nil? || password.nil?)

        if basic_auth
          auth_string = Base64.strict_decode64(basic_auth.to_s).force_encoding('utf-8')
          email, password = auth_string.split(':', 2)
        end

        raise ActionController::ParameterMissing, :email if email.nil?
        raise ActionController::ParameterMissing, :password if password.nil?

        [email.to_s.strip.downcase, password, next_path]
      rescue ArgumentError
        raise ActionController::ParameterMissing, :basic_auth
      end

      def find_or_create_vendor(email)
        ::Spree::Vendor.find_by(notification_email: email) ||
          ::Spree::Vendor.find_by(name: email) ||
          ::Spree::Vendor.create!(
            name: email,
            notification_email: email,
            contact_person_email: email,
            billing_email: email
          )
      end

      def find_or_create_user(email, password)
        Spree.user_class.find_by(email: email) || Spree.user_class.create!(email: email, password: password)
      end

      def assign_vendor_role(user, vendor)
        vendor_role_name = defined?(Spree::Vendor::DEFAULT_VENDOR_ROLE) ? Spree::Vendor::DEFAULT_VENDOR_ROLE : 'vendor'
        vendor_role = Spree::Role.find_or_create_by!(name: vendor_role_name)

        Spree::RoleUser.find_or_create_by!(
          user: user,
          role: vendor_role,
          resource: vendor
        )
      end

      def activate_vendor(vendor)
        return if %w[active approved].include?(vendor.state)

        vendor.start_onboarding! if vendor.respond_to?(:start_onboarding!) && vendor.state == 'invited'
        vendor.approve! if vendor.respond_to?(:approve!) && !%w[active approved].include?(vendor.state)
      end

      def sanitize_next_path(next_path)
        return if next_path.blank?
        return next_path if next_path.start_with?('/') && !next_path.start_with?('//')

        uri = URI.parse(next_path)
        uri.path if uri.host.nil? && uri.scheme.nil? && uri.path.present?
      rescue URI::InvalidURIError
        nil
      end
    end
  end
end
