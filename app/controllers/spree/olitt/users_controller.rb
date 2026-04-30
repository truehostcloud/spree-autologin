require 'base64'
require 'uri'

module Spree
  module Olitt
    class UsersController < Spree::BaseController
      # Auto-login endpoint for vendors. Creates `Spree::AdminUser` on-demand
      # (migrates the legacy user) and assigns vendor-scoped role.
      def auto_login
        email, password, next_path = login_details

        admin_user = nil
        vendor = nil

        ActiveRecord::Base.transaction do
          vendor = find_or_create_vendor(email)

          # Ensure admin user exists and handle legacy password hashes.
          legacy_user = Spree.user_class.find_by('LOWER(email) = ?', email.downcase)
          result = Spree::AdminUserMigrationService.ensure_admin_for_user(source_user: legacy_user, email: email, dry_run: false)
          admin_user = result.admin_user

          begin
            valid_pw = admin_user.valid_password?(password)
          rescue ::BCrypt::Errors::InvalidHash
            valid_pw = false
          end

          unless valid_pw || result.autologin_created || result.reset_token.present?
            raise CanCan::AccessDenied
          end

          # Assign vendor role using app helper if available, otherwise create RoleUser
          assign_vendor_role(admin_user, vendor)
          activate_vendor(vendor)
        end

        sign_in(admin_user, event: :authentication)
        redirect_to next_path, allow_other_host: false
      rescue CanCan::AccessDenied
        redirect_unauthorized_access
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

      def assign_vendor_role(admin_user, vendor)
        vendor_role_name = defined?(Spree::Vendor::DEFAULT_VENDOR_ROLE) ? Spree::Vendor::DEFAULT_VENDOR_ROLE : 'vendor'
        vendor_role = Spree::Role.find_or_create_by!(name: vendor_role_name)

        if vendor.respond_to?(:add_user)
          vendor.add_user(admin_user, vendor.default_user_role || vendor_role)
        else
          Spree::RoleUser.find_or_create_by!(user: admin_user, role: vendor_role, resource: vendor)
        end
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

      def redirect_unauthorized_access
        redirect_to unauthorized_redirect_path,
                    allow_other_host: false,
                    alert: I18n.t('spree.authorization_failure', default: 'You are not authorized to perform this action.')
      end

      def unauthorized_redirect_path
        if spree.respond_to?(:new_spree_user_session_path)
          spree.new_spree_user_session_path
        elsif spree.respond_to?(:login_path)
          spree.login_path
        elsif spree.respond_to?(:root_path)
          spree.root_path
        else
          '/'
        end
      end
    end
  end
end
