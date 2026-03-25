require "rails_helper"

RSpec.describe InvoiceMailer, type: :mailer do
  describe "#invoice_email" do
    before do
      ActionMailer::Base.default_url_options[:host] = "example.com"
    end

    it "attaches the invoice pdf and sends to the customer" do
      invoice = create(:invoice)
      allow_any_instance_of(InvoicePdfBuilder).to receive(:render).and_return("PDF")

      mail = described_class.with(invoice: invoice).invoice_email

      expect(mail.to).to eq([invoice.customer.email])
      expect(mail.subject).to include(invoice.company_name)
      expect(mail.attachments["invoice_#{invoice.id}.pdf"].body.raw_source).to eq("PDF")
    end
  end
end
