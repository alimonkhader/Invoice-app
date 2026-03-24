class InvoicePdfBuilder
  PRIMARY_COLOR = "2F7D57".freeze
  MUTED_TEXT_COLOR = "6B7280".freeze
  BORDER_COLOR = "D9E2DC".freeze
  HEADER_BG = "EDF7F1".freeze
  TOTAL_BG = "F7FAF8".freeze

  def initialize(invoice, view_context:)
    @invoice = invoice
    @view_context = view_context
  end

  def render
    Prawn::Document.new(page_size: "A4", margin: 36).tap do |pdf|
      register_fonts(pdf)
      render_header(pdf)
      render_party_and_meta(pdf)
      render_items_table(pdf)
      render_summary_table(pdf)
      render_footer_note(pdf)
    end.render
  end

  private

  attr_reader :invoice, :view_context

  def register_fonts(pdf)
    pdf.font_families.update(
      "DejaVuSans" => {
        normal: Rails.root.join("app/assets/fonts/DejaVuSans.ttf"),
        bold: Rails.root.join("app/assets/fonts/DejaVuSans-Bold.ttf")
      }
    )
    pdf.font "DejaVuSans"
  end

  def render_header(pdf)
    pdf.fill_color PRIMARY_COLOR
    pdf.text "INVOICE", size: 24, style: :bold
    pdf.fill_color "000000"
    pdf.move_down 4

    pdf.text(invoice.company_name.presence || "Your Company Name", size: 14, style: :bold)
    pdf.fill_color MUTED_TEXT_COLOR
    pdf.text(invoice.address.to_s, size: 10)
    pdf.text("Phone: #{invoice.phone}", size: 10)
    pdf.fill_color "000000"
    pdf.move_down 14
  end

  def render_party_and_meta(pdf)
    box_height = 68
    left_width = (pdf.bounds.width * 0.58).to_f
    right_width = pdf.bounds.width - left_width - 10

    pdf.bounding_box([pdf.bounds.left, pdf.cursor], width: left_width, height: box_height) do
      pdf.stroke_color BORDER_COLOR
      pdf.fill_color HEADER_BG
      pdf.fill_and_stroke_rounded_rectangle [0, box_height], left_width, box_height, 6
      pdf.fill_color PRIMARY_COLOR
      pdf.text_box "Bill To", at: [10, box_height - 10], size: 10, style: :bold
      pdf.fill_color "000000"
      pdf.text_box(invoice.customer&.name.to_s, at: [10, box_height - 26], size: 11, style: :bold)
      pdf.fill_color MUTED_TEXT_COLOR
      pdf.text_box("Phone: #{invoice.customer&.phone}", at: [10, box_height - 42], size: 9)
      pdf.text_box("Email: #{invoice.customer&.email}", at: [10, box_height - 54], size: 9)
      pdf.fill_color "000000"
    end

    pdf.bounding_box([pdf.bounds.left + left_width + 10, pdf.cursor + box_height], width: right_width, height: box_height) do
      pdf.stroke_color BORDER_COLOR
      pdf.fill_color TOTAL_BG
      pdf.fill_and_stroke_rounded_rectangle [0, box_height], right_width, box_height, 6
      pdf.fill_color MUTED_TEXT_COLOR
      pdf.text_box "Invoice No", at: [10, box_height - 12], size: 9
      pdf.text_box "Date", at: [10, box_height - 30], size: 9
      pdf.fill_color "000000"
      pdf.text_box(invoice.invoice_number.presence || invoice.id.to_s, at: [80, box_height - 12], size: 10, style: :bold)
      pdf.text_box(invoice_date.strftime("%d-%m-%Y"), at: [80, box_height - 30], size: 10, style: :bold)
    end

    pdf.move_down box_height + 10
  end

  def render_items_table(pdf)
    table_data = [["Item", "Qty", "Price", "Total"]]

    invoice.invoice_items.each do |item|
      line_total = item.quantity.to_f * item.price.to_f
      table_data << [item.name, item.quantity, inr(item.price), inr(line_total)]
    end

    pdf.table(table_data, header: true, width: pdf.bounds.width, cell_style: { border_color: BORDER_COLOR, padding: 8, size: 10 }) do
      row(0).font_style = :bold
      row(0).background_color = HEADER_BG
      row(0).text_color = PRIMARY_COLOR
      columns(1..3).align = :right
      self.row_colors = ["FFFFFF", "FCFDFC"]
    end

    pdf.move_down 14
  end

  def render_summary_table(pdf)
    summary_data = [
      ["Subtotal", inr(invoice.total)],
      ["CGST (9%)", inr(invoice.cgst)],
      ["SGST (9%)", inr(invoice.sgst)],
      ["Final Total", inr(invoice.final_total)]
    ]

    pdf.table(summary_data, position: :right, width: 230, cell_style: { border_color: BORDER_COLOR, padding: 7, size: 10 }) do
      columns(1).align = :right
      row(0..-2).background_color = TOTAL_BG
      row(-1).font_style = :bold
      row(-1).background_color = HEADER_BG
      row(-1).text_color = PRIMARY_COLOR
    end
  end

  def render_footer_note(pdf)
    pdf.move_down 20
    pdf.stroke_color BORDER_COLOR
    pdf.stroke_horizontal_rule
    pdf.move_down 8
    pdf.fill_color MUTED_TEXT_COLOR
    pdf.text "Thank you for your business.", size: 9, align: :center
    pdf.text "This is a system-generated invoice.", size: 8, align: :center
    pdf.fill_color "000000"
  end

  def invoice_date
    invoice.date || invoice.created_at
  end

  def inr(amount)
    view_context.number_to_currency(amount.to_f, unit: "₹", precision: 2)
  end
end
