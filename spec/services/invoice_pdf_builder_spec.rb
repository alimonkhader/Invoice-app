require "rails_helper"

RSpec.describe InvoicePdfBuilder do
  it "renders a pdf for GST invoices" do
    invoice = create(:invoice)

    pdf = described_class.new(invoice, view_context: ApplicationController.helpers).render

    expect(pdf).to start_with("%PDF")
  end

  it "renders a pdf when GST is disabled" do
    user = create(:user, gst_enabled: false)
    customer = create(:customer, user: user)
    invoice = create(:invoice, user: user, customer: customer)

    pdf = described_class.new(invoice, view_context: ApplicationController.helpers).render

    expect(pdf).to start_with("%PDF")
  end
end
