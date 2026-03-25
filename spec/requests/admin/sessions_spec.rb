require "rails_helper"

RSpec.describe "Admin sessions", type: :request do
  it "renders the login page" do
    get admin_login_path

    expect(response).to have_http_status(:ok)
  end

  it "logs in an admin" do
    admin = create(:user, :admin)

    post admin_session_path, params: { email: admin.email, password: "password123" }

    expect(response).to redirect_to(admin_plans_path)
  end

  it "rejects invalid credentials" do
    admin = create(:user, :admin)

    post admin_session_path, params: { email: admin.email, password: "wrong" }

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "logs out an admin" do
    admin = create(:user, :admin)
    post admin_session_path, params: { email: admin.email, password: "password123" }

    delete admin_session_path

    expect(response).to redirect_to(root_path)
  end
end
