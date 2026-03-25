require "rails_helper"

RSpec.describe "User passwords", type: :request do
  it "always redirects with a generic response when the account exists" do
    user = create(:user)
    allow_any_instance_of(User).to receive(:send_reset_password_instructions).and_return(true)

    post user_password_path, params: { user: { email: user.email.upcase } }

    expect(response).to redirect_to(new_user_session_path)
  end

  it "always redirects with a generic response when the account does not exist" do
    post user_password_path, params: { user: { email: "missing@example.com" } }

    expect(response).to redirect_to(new_user_session_path)
  end
end
