require "rails_helper"

RSpec.describe ApplicationMailer, type: :mailer do
  it "uses the mailer layout and default from address" do
    expect(described_class.default[:from]).to eq(ENV.fetch("MAIL_FROM", "no-reply@invoiceapp.local"))
    expect(described_class._layout).to eq("mailer")
  end
end
