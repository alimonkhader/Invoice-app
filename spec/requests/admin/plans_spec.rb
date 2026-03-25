require "rails_helper"

RSpec.describe "Admin plans", type: :request do
  let(:admin) { create(:user, :admin) }

  before do
    post admin_session_path, params: { email: admin.email, password: "password123" }
  end

  it "renders index" do
    get admin_plans_path

    expect(response).to have_http_status(:ok)
  end

  it "creates a plan" do
    post admin_plans_path, params: { plan: attributes_for(:plan, code: "new-code") }

    expect(response).to redirect_to(admin_plans_path)
    expect(Plan.find_by(code: "new-code")).to be_present
  end

  it "renders errors on invalid create" do
    post admin_plans_path, params: { plan: attributes_for(:plan, name: "", code: "") }

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "renders edit" do
    plan = create(:plan)

    get edit_admin_plan_path(plan)

    expect(response).to have_http_status(:ok)
  end

  it "updates a plan" do
    plan = create(:plan)

    patch admin_plan_path(plan), params: { plan: { name: "Updated" } }

    expect(response).to redirect_to(admin_plans_path)
    expect(plan.reload.name).to eq("Updated")
  end

  it "renders errors on invalid update" do
    plan = create(:plan)

    patch admin_plan_path(plan), params: { plan: { name: "" } }

    expect(response).to have_http_status(:unprocessable_entity)
  end
end
