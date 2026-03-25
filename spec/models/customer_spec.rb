require "rails_helper"

RSpec.describe Customer, type: :model do
  it "belongs to an optional user and restricts invoice deletion" do
    customer = create(:customer)
    create(:invoice, customer: customer, user: customer.user)

    expect(customer.user).to be_present
    expect { customer.destroy! }.to raise_error(ActiveRecord::DeleteRestrictionError)
  end
end
