require "rails_helper"

RSpec.describe "User sessions", type: :request do
  it "logs in an active account user" do
    user = create(:user)

    post user_session_path, params: { user: { email: user.email, password: "password123" } }

    expect(response).to redirect_to(root_path)
  end

  it "rejects admin users on the account login" do
    admin = create(:user, :admin)

    post user_session_path, params: { user: { email: admin.email, password: "password123" } }

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "rejects inactive account users" do
    user = create(:user, active: false, status: "payment_pending")

    post user_session_path, params: { user: { email: user.email, password: "password123" } }

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "rejects wrong passwords" do
    user = create(:user)

    post user_session_path, params: { user: { email: user.email, password: "wrong" } }

    expect(response).to have_http_status(:unprocessable_entity)
  end
end
