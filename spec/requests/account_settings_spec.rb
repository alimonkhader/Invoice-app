require "rails_helper"

RSpec.describe "AccountSettings", type: :request do
  it "redirects guests" do
    get settings_path

    expect(response).to redirect_to(login_path)
  end

  it "shows settings for account users" do
    user = create(:user)
    sign_in user

    get settings_path

    expect(response).to have_http_status(:ok)
  end

  it "updates the gst setting" do
    user = create(:user, gst_enabled: true)
    sign_in user

    patch settings_path, params: { user: { gst_enabled: false } }

    expect(response).to redirect_to(settings_path)
    expect(user.reload.gst_enabled).to be(false)
  end

  it "renders errors on invalid update" do
    user = create(:user)
    sign_in user
    allow_any_instance_of(User).to receive(:update).and_return(false)

    patch settings_path, params: { user: { gst_enabled: false } }

    expect(response).to have_http_status(:unprocessable_entity)
  end
end
