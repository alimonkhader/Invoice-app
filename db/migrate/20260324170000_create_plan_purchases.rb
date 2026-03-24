class CreatePlanPurchases < ActiveRecord::Migration[8.0]
  def change
    create_table :plan_purchases do |t|
      t.references :plan, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.integer :amount, null: false
      t.string :currency, null: false, default: "INR"
      t.string :receipt, null: false
      t.string :razorpay_order_id
      t.string :razorpay_payment_id
      t.string :razorpay_signature
      t.jsonb :order_payload, null: false, default: {}
      t.jsonb :payment_payload, null: false, default: {}
      t.datetime :paid_at
      t.datetime :failed_at
      t.text :failure_reason
      t.timestamps
    end

    add_index :plan_purchases, :receipt, unique: true
    add_index :plan_purchases, :razorpay_order_id, unique: true
    add_index :plan_purchases, :status
  end
end
