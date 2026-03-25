require "rails_helper"

RSpec.describe "Invoices", type: :request do
  let(:user) { create(:user, invoice_limit: 5) }
  let(:customer) { create(:customer, user: user, name: "Buyer", phone: "9999999999", email: "buyer@example.com") }

  before do
    sign_in user
  end

  def invoice_payload(overrides = {})
    {
      invoice_number: "INV-NEW",
      date: Date.current,
      company_name: "Example Company",
      address: "Kochi",
      phone: "9876543210",
      customer_name: "Buyer",
      customer_phone: "9999999999",
      invoice_items_attributes: {
        "0" => { name: "Item", quantity: 2, price: 100 }
      }
    }.merge(overrides)
  end

  it "lists invoices with search and sorting" do
    create(:invoice, user: user, customer: customer, invoice_number: "INV-001", company_name: "Alpha")

    get invoices_path, params: { query: "alpha", sort: "invoice_number", direction: "asc", page: 0 }

    expect(response).to have_http_status(:ok)
  end

  it "renders show and pdf" do
    invoice = create(:invoice, user: user, customer: customer)

    get invoice_path(invoice)
    expect(response).to have_http_status(:ok)

    get invoice_path(invoice, format: :pdf)
    expect(response.media_type).to eq("application/pdf")
  end

  it "renders new and edit pages" do
    invoice = create(:invoice, user: user, customer: customer)

    get new_invoice_path
    expect(response).to have_http_status(:ok)

    get edit_invoice_path(invoice)
    expect(response).to have_http_status(:ok)
  end

  it "creates an invoice and reuses the matching customer by phone" do
    customer

    post invoices_path, params: { invoice: invoice_payload }

    expect(response).to redirect_to(invoice_path(Invoice.last))
    expect(Invoice.last.customer).to eq(customer)
  end

  it "creates a customer by matching name when phone is blank in existing records" do
    named_customer = create(:customer, user: user, name: "Same Name", phone: "1231231234")

    post invoices_path, params: { invoice: invoice_payload(customer_name: "Same Name", customer_phone: "8888888888") }

    expect(response).to redirect_to(invoice_path(Invoice.last))
    expect(Invoice.last.customer).not_to eq(named_customer)
  end

  it "renders errors when customer details are missing" do
    post invoices_path, params: { invoice: invoice_payload(customer_name: "", customer_phone: "") }

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "renders errors when customer save fails" do
    allow_any_instance_of(Customer).to receive(:save).and_return(false)
    errors = ActiveModel::Errors.new(Customer.new)
    errors.add(:name, "is invalid")
    allow_any_instance_of(Customer).to receive(:errors).and_return(errors)

    post invoices_path, params: { invoice: invoice_payload(customer_name: "New Buyer", customer_phone: "7777777777") }

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "updates an invoice" do
    invoice = create(:invoice, user: user, customer: customer)

    patch invoice_path(invoice), params: { invoice: invoice_payload(invoice_number: "INV-UPD") }

    expect(response).to have_http_status(:see_other)
    expect(invoice.reload.invoice_number).to eq("INV-UPD")
  end

  it "renders errors on invalid update" do
    invoice = create(:invoice, user: user, customer: customer)

    patch invoice_path(invoice), params: { invoice: invoice_payload(customer_name: "", customer_phone: "") }

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "destroys an invoice" do
    invoice = create(:invoice, user: user, customer: customer)

    delete invoice_path(invoice)

    expect(response).to have_http_status(:see_other)
  end

  it "queues email when the customer has an email" do
    invoice = create(:invoice, user: user, customer: customer)

    post send_email_invoice_path(invoice)

    expect(response).to redirect_to(invoice_path(invoice))
  end

  it "rejects email when the customer email is missing" do
    invoice = create(:invoice, user: user, customer: create(:customer, user: user, email: nil, phone: "9999999999"))

    post send_email_invoice_path(invoice)

    expect(response).to redirect_to(invoice_path(invoice))
  end

  it "redirects to whatsapp when the customer has a phone" do
    invoice = create(:invoice, user: user, customer: customer)

    get share_whatsapp_invoice_path(invoice)

    expect(response).to have_http_status(:redirect)
    expect(response.location).to include("https://wa.me/")
  end

  it "rejects whatsapp when the customer phone is missing" do
    invoice = create(:invoice, user: user, customer: create(:customer, user: user, phone: nil, email: "buyer@example.com"))

    get share_whatsapp_invoice_path(invoice)

    expect(response).to redirect_to(invoice_path(invoice))
  end

  it "blocks new invoice creation when the limit is reached" do
    limited_plan = create(:plan, invoice_limit: 1)
    limited_user = create(:user, plan: limited_plan)
    limited_user.update_columns(invoice_limit: 1)
    limited_customer = create(:customer, user: limited_user)
    create(:invoice, user: limited_user, customer: limited_customer)
    sign_in limited_user

    get new_invoice_path
    expect(response).to redirect_to(invoices_path)

    post invoices_path, params: { invoice: invoice_payload }
    expect(response).to redirect_to(invoices_path)
  end
end
