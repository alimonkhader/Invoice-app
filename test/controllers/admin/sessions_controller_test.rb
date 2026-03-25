require "test_helper"

class Admin::SessionsControllerTest < ActionDispatch::IntegrationTest
  test "creates an admin session with valid credentials" do
    admin = User.create!(
      name: "Admin User",
      email: "admin@example.com",
      role: "admin",
      active: true,
      password: "password123",
      password_confirmation: "password123"
    )

    post admin_session_url, params: {
      email: admin.email,
      password: "password123"
    }

    assert_redirected_to admin_plans_url
  end
end
