require 'base64'
require 'uri'

module Spree
  module Olitt
    class UsersController < Spree::BaseController
      # Auto-login endpoint for vendors. Resolves the vendor and admin user
      # on demand, then links them through `spree_vendor_users`.
      def auto_login
        email, password, next_path = login_details

        vendor = find_vendor(email)
        raise CanCan::AccessDenied if vendor.blank?
        admin_user = nil

        ActiveRecord::Base.transaction do
          legacy_user = Spree.user_class.find_by('LOWER(email) = ?', email.downcase)
          vendor_user = existing_vendor_user_link(vendor: vendor, legacy_user: legacy_user)

          if vendor_user.present? && vendor_user.admin_user_id.present?
            admin_user = Spree.admin_user_class.find_by(id: vendor_user.admin_user_id)
          end

          admin_user ||= find_or_create_admin_user(email: email, password: password, legacy_user: legacy_user)

          unless admin_user.persisted? && password_matches?(admin_user, password)
            raise CanCan::AccessDenied
          end

          assign_vendor_role(admin_user, vendor)
          link_admin_user_to_vendor!(vendor: vendor, admin_user: admin_user, legacy_user: legacy_user)
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

      def find_vendor(email)
        ::Spree::Vendor.find_by(slug: email) ||
          ::Spree::Vendor.find_by(notification_email: email) ||
          ::Spree::Vendor.find_by(name: email)
      end

      def find_or_create_admin_user(email:, password:, legacy_user: nil)
        admin_user = Spree.admin_user_class.find_by('LOWER(email) = ?', email.downcase)
        return admin_user if admin_user.present?

        admin_user = Spree.admin_user_class.new(email: email, login: email)
        admin_user.password = password
        admin_user.password_confirmation = password if admin_user.respond_to?(:password_confirmation)

        if legacy_user.present?
          admin_user.first_name ||= legacy_user.first_name if admin_user.respond_to?(:first_name=)
          admin_user.last_name ||= legacy_user.last_name if admin_user.respond_to?(:last_name=)
          admin_user.selected_locale ||= legacy_user.selected_locale if admin_user.respond_to?(:selected_locale=)
        end

        admin_user.save!
        admin_user
      end

      def password_matches?(admin_user, password)
        admin_user.valid_password?(password)
      rescue ::BCrypt::Errors::InvalidHash
        false
      end

      def assign_vendor_role(admin_user, vendor)
        vendor_role_name = defined?(Spree::Vendor::DEFAULT_VENDOR_ROLE) ? Spree::Vendor::DEFAULT_VENDOR_ROLE : 'vendor'
        vendor_role = Spree::Role.find_or_create_by!(name: vendor_role_name)

        Spree::RoleUser.find_or_create_by!(user: admin_user, role: vendor_role, resource: vendor)
      end

      def link_admin_user_to_vendor!(vendor:, admin_user:, legacy_user: nil)
        return unless ActiveRecord::Base.connection.data_source_exists?('spree_vendor_users')

        vendor_user = existing_vendor_user_link(vendor: vendor, legacy_user: legacy_user)

        if vendor_user.nil? && vendor_user_link_class.column_names.include?('admin_user_id')
          vendor_user = vendor_user_link_class.find_by(vendor_id: vendor.id, admin_user_id: admin_user.id)
        end

        vendor_user ||= vendor_user_link_class.new(vendor_id: vendor.id)
        vendor_user.admin_user_id = admin_user.id if vendor_user.respond_to?(:admin_user_id=)

        vendor_user.save! if vendor_user.new_record? || vendor_user.changed?
      end

      def existing_vendor_user_link(vendor:, legacy_user: nil)
        return unless defined?(Spree::VendorUser)
        return unless ActiveRecord::Base.connection.data_source_exists?('spree_vendor_users')

        if legacy_user.present?
          vendor_user = vendor_user_link_class.find_by(vendor_id: vendor.id, user_id: legacy_user.id)
          return vendor_user if vendor_user.present?
        end

        vendor_user_link_class.where(vendor_id: vendor.id).where.not(admin_user_id: nil).first ||
          vendor_user_link_class.find_by(vendor_id: vendor.id, admin_user_id: nil)
      end

      def vendor_user_link_class
        Spree::VendorUser
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
