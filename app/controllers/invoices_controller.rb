class InvoicesController < ApplicationController
  require "cgi"

  before_action :set_invoice, only: %i[show edit update destroy send_email share_whatsapp]

  # GET /invoices
  def index
    @invoices = Invoice.includes(:customer).order(created_at: :desc)
  end

  # GET /invoices/1
  def show
    respond_to do |format|
      format.html
      format.pdf { send_invoice_pdf }
    end
  end

  # GET /invoices/new
  def new
    @invoice = Invoice.new(default_company_attributes)
    @invoice.invoice_items.build
  end

  # GET /invoices/1/edit
  def edit
  end

  # POST /invoices
  def create
    @invoice = Invoice.new(invoice_params)
    assign_customer_from_input(@invoice)

    respond_to do |format|
      if @invoice.errors.empty? && @invoice.save
        format.html { redirect_to @invoice, notice: "Invoice was successfully created." }
        format.json { render :show, status: :created, location: @invoice }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @invoice.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /invoices/1
  def update
    @invoice.assign_attributes(invoice_params)
    assign_customer_from_input(@invoice)

    respond_to do |format|
      if @invoice.errors.empty? && @invoice.save
        format.html { redirect_to @invoice, notice: "Invoice was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @invoice }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @invoice.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /invoices/1
  def destroy
    @invoice.destroy!

    respond_to do |format|
      format.html { redirect_to invoices_path, notice: "Invoice was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def send_email
    if @invoice.customer&.email.blank?
      redirect_to @invoice, alert: "Customer email is missing."
      return
    end

    InvoiceMailer.with(invoice: @invoice).invoice_email.deliver_later
    redirect_to @invoice, notice: "Invoice email has been queued."
  end

  def share_whatsapp
    if @invoice.customer&.phone.blank?
      redirect_to @invoice, alert: "Customer phone is missing."
      return
    end

    redirect_to whatsapp_share_url(@invoice), allow_other_host: true
  end

  private

  def set_invoice
    @invoice = Invoice.includes(:customer, :invoice_items).find(params[:id])
  end

  def invoice_params
    params.require(:invoice).permit(
      :invoice_number,
      :date,
      :company_name,
      :address,
      :phone,
      invoice_items_attributes: [:id, :name, :quantity, :price, :_destroy]
    )
  end

  def default_company_attributes
    {
      company_name: "Alimon Tech",
      address: "Kochi, Kerala",
      phone: "9876543210"
    }
  end

  def send_invoice_pdf
    send_data invoice_pdf_data(@invoice),
              filename: "invoice_#{@invoice.id}.pdf",
              type: "application/pdf",
              disposition: "inline"
  end

  def invoice_pdf_data(invoice)
    InvoicePdfBuilder.new(invoice, view_context: view_context).render
  end

  def assign_customer_from_input(invoice)
    name = inline_customer_name
    phone = inline_customer_phone
    if name.blank?
      invoice.errors.add(:base, "Customer name is required.")
      return
    end
    if phone.blank?
      invoice.errors.add(:base, "Customer phone is required.")
      return
    end

    customer = find_matching_customer(name, phone) || Customer.new
    customer.name = name if name.present?
    customer.phone = phone if phone.present?

    if customer.name.blank?
      invoice.errors.add(:base, "Customer name is required when adding customer details.")
      return
    end

    unless customer.save
      customer.errors.full_messages.each { |message| invoice.errors.add(:base, message) }
      return
    end

    invoice.customer = customer
  end

  def find_matching_customer(name, phone)
    return Customer.find_by(phone: phone) if phone.present?
    return Customer.where("LOWER(name) = ?", name.downcase).first if name.present?

    nil
  end

  def inline_customer_name
    params.dig(:invoice, :customer_name).to_s.strip
  end

  def inline_customer_phone
    params.dig(:invoice, :customer_phone).to_s.strip
  end

  def whatsapp_share_url(invoice)
    phone = invoice.customer.phone.to_s.gsub(/\D/, "")
    pdf_url = invoice_url(invoice, format: :pdf)
    amount = helpers.number_to_currency(invoice.final_total.to_f, unit: "₹", precision: 2)
    message = <<~MSG.squish
      Hi #{invoice.customer.name}, your invoice ##{invoice.invoice_number.presence || invoice.id}
      for #{amount} is ready. View or download it here: #{pdf_url}
    MSG

    "https://wa.me/#{phone}?text=#{CGI.escape(message)}"
  end
end