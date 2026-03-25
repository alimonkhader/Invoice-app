require "rails_helper"

RSpec.describe InvoicesController, type: :controller do
  let(:user) { create(:user) }

  before do
    allow(controller).to receive(:current_account_user).and_return(user)
  end

  describe "#assign_customer_from_input" do
    it "adds an error when the phone is blank" do
      invoice = build(:invoice, user: user)
      allow(controller).to receive(:params).and_return(ActionController::Parameters.new(invoice: { customer_name: "Buyer", customer_phone: "" }))

      controller.send(:assign_customer_from_input, invoice)

      expect(invoice.errors[:base]).to include("Customer phone is required.")
    end

    it "adds an error when the built customer still has no name" do
      invoice = build(:invoice, user: user)
      nameless_customer = instance_double(Customer, name: "", phone: nil)
      allow(nameless_customer).to receive(:name=)
      allow(nameless_customer).to receive(:phone=)
      allow(nameless_customer).to receive(:user=)
      allow(controller).to receive(:params).and_return(ActionController::Parameters.new(invoice: { customer_name: "Buyer", customer_phone: "123" }))
      allow(controller).to receive(:find_matching_customer).and_return(nil)
      allow(controller).to receive(:scoped_customers).and_return(double(new: nameless_customer))

      controller.send(:assign_customer_from_input, invoice)

      expect(invoice.errors[:base]).to include("Customer name is required when adding customer details.")
    end
  end

  describe "#find_matching_customer" do
    it "matches by lowercase name when phone is blank" do
      customer = create(:customer, user: user, name: "Buyer Name", phone: "999")

      result = controller.send(:find_matching_customer, "buyer name", "")

      expect(result).to eq(customer)
    end

    it "returns nil when both phone and name are blank" do
      expect(controller.send(:find_matching_customer, "", "")).to be_nil
    end
  end
end
