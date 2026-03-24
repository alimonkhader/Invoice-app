class InvoiceMailer < ApplicationMailer
  def invoice_email
    @invoice = params[:invoice]
    @customer = @invoice.customer

    attachments["invoice_#{@invoice.id}.pdf"] =
      InvoicePdfBuilder.new(@invoice, view_context: ApplicationController.helpers).render

    mail(
      to: @customer.email,
      subject: "Invoice ##{@invoice.invoice_number.presence || @invoice.id} from #{@invoice.company_name}"
    )
  end
end
