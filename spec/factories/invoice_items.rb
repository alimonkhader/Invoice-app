FactoryBot.define do
  factory :invoice_item do
    association :invoice
    name { "Coconut Oil" }
    quantity { 2 }
    price { 150.0 }
  end
end
