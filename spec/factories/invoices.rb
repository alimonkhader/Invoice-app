FactoryBot.define do
  factory :invoice do
    association :customer
    user { customer.user }
    sequence(:invoice_number) { |n| "INV-#{n}" }
    date { Date.current }
    company_name { "Example Company" }
    address { "Kochi" }
    phone { "9876543210" }

    after(:build) do |invoice|
      invoice.invoice_items << build(:invoice_item, invoice: invoice) if invoice.invoice_items.empty?
    end
  end
end
