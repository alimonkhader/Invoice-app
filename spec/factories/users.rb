FactoryBot.define do
  factory :user do
    association :plan
    sequence(:name) { |n| "User #{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    role { "account_admin" }
    company_name { "Example Company" }
    phone { "9876543210" }
    status { "active" }
    active { true }
    password { "password123" }
    password_confirmation { "password123" }
    started_on { Date.current }
    expires_on { Date.current.advance(months: plan.duration_months) if plan&.duration_months.to_i.positive? }
    invoice_limit { plan&.invoice_limit }
    plan_price { plan&.price || 0 }
    excel_reports_enabled { plan&.excel_reports || false }

    trait :admin do
      plan { nil }
      role { "admin" }
      company_name { nil }
      phone { nil }
      status { "active" }
      invoice_limit { nil }
      plan_price { 0 }
      excel_reports_enabled { true }
      expires_on { nil }
    end
  end
end
