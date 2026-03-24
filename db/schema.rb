# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_03_24_193000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "companies", force: :cascade do |t|
    t.string "name"
    t.string "address"
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "customers", force: :cascade do |t|
    t.string "name"
    t.string "phone"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_customers_on_user_id"
  end

  create_table "invoice_items", force: :cascade do |t|
    t.string "name"
    t.integer "quantity"
    t.decimal "price"
    t.bigint "invoice_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_invoice_items_on_invoice_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.string "invoice_number"
    t.date "date"
    t.bigint "customer_id", null: false
    t.decimal "total"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "cgst"
    t.decimal "sgst"
    t.decimal "final_total"
    t.string "company_name"
    t.string "address"
    t.string "phone"
    t.bigint "user_id"
    t.index ["customer_id"], name: "index_invoices_on_customer_id"
    t.index ["user_id"], name: "index_invoices_on_user_id"
  end

  create_table "plan_purchases", force: :cascade do |t|
    t.bigint "plan_id", null: false
    t.bigint "user_id", null: false
    t.string "status", default: "pending", null: false
    t.integer "amount", null: false
    t.string "currency", default: "INR", null: false
    t.string "receipt", null: false
    t.string "razorpay_order_id"
    t.string "razorpay_payment_id"
    t.string "razorpay_signature"
    t.jsonb "order_payload", default: {}, null: false
    t.jsonb "payment_payload", default: {}, null: false
    t.datetime "paid_at"
    t.datetime "failed_at"
    t.text "failure_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plan_id"], name: "index_plan_purchases_on_plan_id"
    t.index ["razorpay_order_id"], name: "index_plan_purchases_on_razorpay_order_id", unique: true
    t.index ["receipt"], name: "index_plan_purchases_on_receipt", unique: true
    t.index ["status"], name: "index_plan_purchases_on_status"
    t.index ["user_id"], name: "index_plan_purchases_on_user_id"
  end

  create_table "plans", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.integer "price", default: 0, null: false
    t.integer "invoice_limit"
    t.integer "duration_months", default: 0, null: false
    t.boolean "excel_reports", default: false, null: false
    t.text "description"
    t.boolean "active", default: true, null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_plans_on_code", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.bigint "plan_id"
    t.string "name", null: false
    t.string "company_name"
    t.string "email", null: false
    t.string "phone"
    t.string "role", null: false
    t.string "status", default: "active", null: false
    t.date "started_on"
    t.date "expires_on"
    t.integer "invoice_limit"
    t.integer "plan_price", default: 0, null: false
    t.boolean "excel_reports_enabled", default: false, null: false
    t.string "password_salt", null: false
    t.string "password_digest", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.boolean "gst_enabled", default: true, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["plan_id"], name: "index_users_on_plan_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "customers", "users"
  add_foreign_key "invoice_items", "invoices"
  add_foreign_key "invoices", "customers"
  add_foreign_key "invoices", "users"
  add_foreign_key "plan_purchases", "plans"
  add_foreign_key "plan_purchases", "users"
  add_foreign_key "users", "plans"
end
