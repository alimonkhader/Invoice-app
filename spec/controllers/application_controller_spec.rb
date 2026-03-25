require "rails_helper"

RSpec.describe ApplicationController, type: :controller do
  controller(ApplicationController) do
    before_action :require_admin_authentication, only: :admin_only
    before_action :require_account_authentication, only: :account_only
    before_action :require_portal_authentication, only: :portal_only

    def admin_only
      head :ok
    end

    def account_only
      head :ok
    end

    def portal_only
      head :ok
    end
  end

  before do
    routes.draw do
      get "admin_only" => "anonymous#admin_only"
      get "account_only" => "anonymous#account_only"
      get "portal_only" => "anonymous#portal_only"
    end
  end

  it "redirects guests from admin-only actions" do
    get :admin_only

    expect(response).to redirect_to(admin_login_path)
  end

  it "allows admins through portal-only actions" do
    admin = create(:user, :admin)
    session[:admin_id] = admin.id

    get :portal_only

    expect(response).to have_http_status(:ok)
  end

  it "redirects guests from portal-only actions" do
    get :portal_only

    expect(response).to redirect_to(login_path)
  end

  it "allows signed-in account users through account-only actions" do
    user = create(:user)
    sign_in user

    get :account_only

    expect(response).to have_http_status(:ok)
  end
end
