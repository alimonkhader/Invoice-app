FactoryBot.define do
  factory :plan do
    sequence(:name) { |n| "Plan #{n}" }
    sequence(:code) { |n| "plan_#{n}" }
    price { 1000 }
    duration_months { 1 }
    invoice_limit { 50 }
    excel_reports { false }
    active { true }
    sequence(:position) { |n| n }
    description { "Plan description" }
  end
end
