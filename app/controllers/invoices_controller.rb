class InvoicesController < ApplicationController
  require "cgi"

  INVOICES_PER_PAGE = 10
  SORTABLE_INVOICE_COLUMNS = {
    "invoice_number" => "invoices.invoice_number",
    "customer_name" => "customers.name",
    "date" => "invoices.date",
    "total" => "invoices.total",
    "final_total" => "invoices.final_total",
    "created_at" => "invoices.created_at"
  }.freeze

  before_action :require_account_authentication
  before_action :redirect_if_invoice_limit_reached, only: %i[new create]
  before_action :set_invoice, only: %i[show edit update destroy send_email share_whatsapp]

  helper_method :current_sort, :current_direction

  def index
    invoices_scope = current_account_user.invoices.left_joins(:customer).includes(:customer)
    invoices_scope = apply_search(invoices_scope)
    invoices_scope = invoices_scope.order(Arel.sql("#{sort_column} #{sort_direction}, invoices.created_at DESC"))

    @page = normalized_page
    @query = params[:query].to_s.strip
    @total_invoices = invoices_scope.count
    @total_pages = [(@total_invoices.to_f / INVOICES_PER_PAGE).ceil, 1].max
    @page = @total_pages if @page > @total_pages
    @invoices = invoices_scope.offset((@page - 1) * INVOICES_PER_PAGE).limit(INVOICES_PER_PAGE)
  end

  def show
    respond_to do |format|
      format.html
      format.pdf { send_invoice_pdf }
    end
  end

  def new
    @invoice = Invoice.new(default_company_attributes)
    @invoice.invoice_items.build
  end

  def edit
  end

  def create
    @invoice = Invoice.new(invoice_params)
    @invoice.user = current_account_user
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
    @invoice = current_account_user.invoices.includes(:customer, :invoice_items).find(params[:id])
  end

  def redirect_if_invoice_limit_reached
    return unless invoice_limit_reached?

    redirect_to invoices_path, alert: "Your current plan has reached its invoice limit. Please renew or upgrade your package."
  end

  def invoice_limit_reached?
    current_account_user.invoice_limit.present? && current_account_user.invoices.count >= current_account_user.invoice_limit
  end

  def scoped_customers
    current_account_user.customers
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

    customer = find_matching_customer(name, phone) || scoped_customers.new
    customer.name = name if name.present?
    customer.phone = phone if phone.present?
    customer.user = current_account_user

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
    return scoped_customers.find_by(phone: phone) if phone.present?
    return scoped_customers.where("LOWER(name) = ?", name.downcase).first if name.present?

    nil
  end

  def inline_customer_name
    params.dig(:invoice, :customer_name).to_s.strip
  end

  def inline_customer_phone
    params.dig(:invoice, :customer_phone).to_s.strip
  end

  def normalized_page
    page = params[:page].to_i
    page.positive? ? page : 1
  end

  def current_sort
    params[:sort].presence_in(SORTABLE_INVOICE_COLUMNS.keys) || "created_at"
  end

  def current_direction
    params[:direction] == "asc" ? "asc" : "desc"
  end

  def sort_column
    SORTABLE_INVOICE_COLUMNS.fetch(current_sort)
  end

  def sort_direction
    current_direction.upcase
  end

  def apply_search(scope)
    query = params[:query].to_s.strip
    return scope unless query.present?

    sanitized_query = "%#{ActiveRecord::Base.sanitize_sql_like(query.downcase)}%"
    scope.where(
      "LOWER(invoices.invoice_number) LIKE :query OR LOWER(invoices.company_name) LIKE :query OR LOWER(customers.name) LIKE :query",
      query: sanitized_query
    )
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
