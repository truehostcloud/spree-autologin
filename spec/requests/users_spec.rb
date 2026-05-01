require 'rails_helper'

RSpec.describe 'Users', type: :request do
  describe 'GET /admin/auto_login' do
    it 'allows vendor auto-login even when the current store belongs to another vendor' do
      vendor = create(:vendor,
                      name: 'vendor@example.com',
                      notification_email: 'vendor@example.com',
                      contact_person_email: 'vendor@example.com')
      other_vendor = create(:vendor,
                             name: 'other@example.com',
                             notification_email: 'other@example.com',
                             contact_person_email: 'other@example.com')
      current_store = instance_double(Spree::Store, vendor_id: other_vendor.id, vendor: other_vendor)

      allow_any_instance_of(Spree::Olitt::UsersController).to receive(:current_store).and_return(current_store)

      get '/admin/auto_login', params: { email: vendor.contact_person_email, password: 'Password123', next: '/admin' }

      expect(response).to have_http_status(:found)
      expect(response.headers['Location']).to end_with('/admin')
    end
  end
end
