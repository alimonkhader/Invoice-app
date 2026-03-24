plans = [
  {
    name: "Trial",
    code: "trial",
    price: 0,
    invoice_limit: 25,
    duration_months: 0,
    excel_reports: false,
    description: "Free trial with up to 25 invoices.",
    active: true,
    position: 1
  },
  {
    name: "Basic",
    code: "basic",
    price: 299,
    invoice_limit: nil,
    duration_months: 1,
    excel_reports: false,
    description: "One-month plan with unlimited invoices.",
    active: true,
    position: 2
  },
  {
    name: "Premium",
    code: "premium",
    price: 499,
    invoice_limit: nil,
    duration_months: 3,
    excel_reports: true,
    description: "Three-month plan with unlimited invoices and XLSX reports.",
    active: true,
    position: 3
  }
]

plans.each do |attributes|
  plan = Plan.find_or_initialize_by(code: attributes[:code])
  plan.assign_attributes(attributes)
  plan.save!
end

admin_email = ENV.fetch("ADMIN_EMAIL", "admin@invoiceapp.local")
admin_password = ENV.fetch("ADMIN_PASSWORD", "admin123")

admin = User.find_or_initialize_by(email: admin_email.downcase)
admin.assign_attributes(
  name: "Super Admin",
  role: "admin",
  status: "active",
  active: true
)
admin.password = admin_password if admin.new_record? || ENV.key?("ADMIN_PASSWORD")
admin.save!
