require "rails_helper"

RSpec.describe "Customers", type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  it "lists customers" do
    create(:customer, user: user)

    get customers_path

    expect(response).to have_http_status(:ok)
  end

  it "shows a customer" do
    customer = create(:customer, user: user)

    get customer_path(customer)

    expect(response).to have_http_status(:ok)
  end

  it "renders new and edit pages" do
    customer = create(:customer, user: user)

    get new_customer_path
    expect(response).to have_http_status(:ok)

    get edit_customer_path(customer)
    expect(response).to have_http_status(:ok)
  end

  it "creates a customer" do
    post customers_path, params: { customer: { name: "New", phone: "1111111111", email: "new@example.com" } }

    expect(response).to redirect_to(customer_path(Customer.last))
  end

  it "renders validation errors on create" do
    allow_any_instance_of(Customer).to receive(:save).and_return(false)
    allow_any_instance_of(Customer).to receive(:errors).and_return(ActiveModel::Errors.new(Customer.new))

    post customers_path, params: { customer: { name: "", phone: "", email: "" } }

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "updates a customer" do
    customer = create(:customer, user: user)

    patch customer_path(customer), params: { customer: { name: "Updated", phone: customer.phone, email: customer.email } }

    expect(response).to have_http_status(:see_other)
    expect(customer.reload.name).to eq("Updated")
  end

  it "renders validation errors on update" do
    customer = create(:customer, user: user)
    allow_any_instance_of(Customer).to receive(:update).and_return(false)
    allow_any_instance_of(Customer).to receive(:errors).and_return(ActiveModel::Errors.new(Customer.new))

    patch customer_path(customer), params: { customer: { name: "" } }

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "destroys a customer" do
    customer = create(:customer, user: user)

    delete customer_path(customer)

    expect(response).to have_http_status(:see_other)
  end
end
