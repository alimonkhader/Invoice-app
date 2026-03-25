require "rails_helper"

RSpec.describe "Admin accounts", type: :request do
  it "lists account admins for admins" do
    admin = create(:user, :admin)
    create(:user)
    post admin_session_path, params: { email: admin.email, password: "password123" }

    get admin_accounts_path

    expect(response).to have_http_status(:ok)
  end
end
