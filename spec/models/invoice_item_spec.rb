require "rails_helper"

RSpec.describe InvoiceItem, type: :model do
  it "belongs to an invoice" do
    item = create(:invoice_item)

    expect(item.invoice).to be_present
  end
end
