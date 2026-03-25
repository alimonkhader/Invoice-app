FactoryBot.define do
  factory :customer do
    association :user
    sequence(:name) { |n| "Customer #{n}" }
    sequence(:email) { |n| "customer#{n}@example.com" }
    phone { "9999999999" }
  end
end
