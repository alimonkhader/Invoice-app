require "rails_helper"

RSpec.describe "Reports", type: :request do
  let(:user) { create(:user) }
  let(:customer) { create(:customer, user: user) }

  before do
    user.update_columns(excel_reports_enabled: true)
    sign_in user
    create(:invoice, user: user, customer: customer, date: Date.new(2026, 3, 25), final_total: 118, cgst: 9, sgst: 9, total: 100, company_name: "Co")
    create(:invoice, user: user, customer: customer, date: Date.new(2026, 2, 20), final_total: 236, cgst: 18, sgst: 18, total: 200, company_name: "Co")
  end

  it "renders the purchase report and falls back on invalid dates" do
    get purchase_reports_path, params: { date: "bad-date", month: "bad-month" }

    expect(response).to have_http_status(:ok)
  end

  it "downloads xlsx reports when the plan allows it" do
    get purchase_reports_xlsx_path, params: { month: "2026-03" }

    expect(response.media_type).to eq("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
  end

  it "blocks xlsx reports when the plan does not allow it" do
    user.update_columns(excel_reports_enabled: false)

    get purchase_reports_xlsx_path, params: { month: "2026-03" }

    expect(response).to redirect_to(purchase_reports_path(month: "2026-03"))
  end
end
