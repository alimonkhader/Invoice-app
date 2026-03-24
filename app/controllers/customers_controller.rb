class CustomersController < ApplicationController
  before_action :require_portal_authentication
  before_action :set_customer, only: %i[show edit update destroy]

  def index
    @customers = Customer.order(:name)
  end

  def show
  end

  def new
    @customer = Customer.new
  end

  def edit
  end

  def create
    @customer = Customer.new(customer_params)

    return render_create_success if @customer.save

    render_validation_errors(:new)
  end

  def update
    return render_update_success if @customer.update(customer_params)

    render_validation_errors(:edit)
  end

  def destroy
    @customer.destroy!

    respond_to do |format|
      format.html { redirect_to customers_path, notice: "Customer was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_customer
    @customer = Customer.find(params.expect(:id))
  end

  def customer_params
    params.expect(customer: %i[name phone email])
  end

  def render_create_success
    respond_to do |format|
      format.html { redirect_to @customer, notice: "Customer was successfully created." }
      format.json { render :show, status: :created, location: @customer }
    end
  end

  def render_update_success
    respond_to do |format|
      format.html { redirect_to @customer, notice: "Customer was successfully updated.", status: :see_other }
      format.json { render :show, status: :ok, location: @customer }
    end
  end

  def render_validation_errors(template)
    respond_to do |format|
      format.html { render template, status: :unprocessable_entity }
      format.json { render json: @customer.errors, status: :unprocessable_entity }
    end
  end
end
