FactoryBot.define do
  factory :plan_purchase do
    association :plan
    association :user
    status { "pending" }
    amount { plan.price }
    currency { "INR" }
    sequence(:receipt) { |n| "plan_receipt_#{n}" }
    sequence(:razorpay_order_id) { |n| "order_#{n}" }
    order_payload { {} }
    payment_payload { {} }
  end
end
