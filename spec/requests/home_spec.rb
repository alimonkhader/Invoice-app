require "rails_helper"

RSpec.describe "Home", type: :request do
  it "renders for guests" do
    create(:plan, price: 0, active: true)

    get root_path

    expect(response).to have_http_status(:ok)
  end

  it "renders for account users inside the downgrade window" do
    user = create(:user, expires_on: Date.current + 7.days)
    sign_in user

    get root_path

    expect(response).to have_http_status(:ok)
  end

  it "renders for admins without account plan options" do
    admin = create(:user, :admin)
    post admin_session_path, params: { email: admin.email, password: "password123" }

    get root_path

    expect(response).to have_http_status(:ok)
  end
end
