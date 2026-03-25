class PlanPurchaseInvoicePdfBuilder
  PRIMARY_COLOR = "2F7D57".freeze
  MUTED_TEXT_COLOR = "6B7280".freeze
  BORDER_COLOR = "D9E2DC".freeze
  HEADER_BG = "EDF7F1".freeze
  TOTAL_BG = "F7FAF8".freeze

  def initialize(plan_purchase, view_context:)
    @plan_purchase = plan_purchase
    @view_context = view_context
  end

  def render
    Prawn::Document.new(page_size: "A4", margin: 36).tap do |pdf|
      register_fonts(pdf)
      render_header(pdf)
      render_customer_and_order_meta(pdf)
      render_plan_table(pdf)
      render_summary(pdf)
      render_footer(pdf)
    end.render
  end

  private

  attr_reader :plan_purchase, :view_context

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
    pdf.text "PLAN PURCHASE INVOICE", size: 22, style: :bold
    pdf.fill_color "000000"
    pdf.move_down 4

    pdf.text "Nilam Invoice", size: 14, style: :bold
    pdf.fill_color MUTED_TEXT_COLOR
    pdf.text "Plan billing, payment tracking, and account activation", size: 10
    pdf.fill_color "000000"
    pdf.move_down 14
  end

  def render_customer_and_order_meta(pdf)
    box_height = 92
    left_width = (pdf.bounds.width * 0.56).to_f
    right_width = pdf.bounds.width - left_width - 10

    pdf.bounding_box([pdf.bounds.left, pdf.cursor], width: left_width, height: box_height) do
      pdf.stroke_color BORDER_COLOR
      pdf.fill_color HEADER_BG
      pdf.fill_and_stroke_rounded_rectangle [0, box_height], left_width, box_height, 6
      pdf.fill_color PRIMARY_COLOR
      pdf.text_box "Billed To", at: [10, box_height - 10], size: 10, style: :bold
      pdf.fill_color "000000"
      pdf.text_box(plan_purchase.user.company_name.to_s, at: [10, box_height - 28], size: 11, style: :bold)
      pdf.fill_color MUTED_TEXT_COLOR
      pdf.text_box(plan_purchase.user.name.to_s, at: [10, box_height - 44], size: 9)
      pdf.text_box("Email: #{plan_purchase.user.email}", at: [10, box_height - 58], size: 9)
      pdf.text_box("Phone: #{plan_purchase.user.phone}", at: [10, box_height - 72], size: 9)
      pdf.fill_color "000000"
    end

    pdf.bounding_box([pdf.bounds.left + left_width + 10, pdf.cursor + box_height], width: right_width, height: box_height) do
      pdf.stroke_color BORDER_COLOR
      pdf.fill_color TOTAL_BG
      pdf.fill_and_stroke_rounded_rectangle [0, box_height], right_width, box_height, 6
      pdf.fill_color MUTED_TEXT_COLOR
      pdf.text_box "Order No", at: [10, box_height - 12], size: 9
      pdf.text_box "Receipt", at: [10, box_height - 28], size: 9
      pdf.text_box "Status", at: [10, box_height - 44], size: 9
      pdf.text_box "Date", at: [10, box_height - 60], size: 9
      pdf.fill_color "000000"
      pdf.text_box(plan_purchase.display_number, at: [80, box_height - 12], size: 10, style: :bold)
      pdf.text_box(plan_purchase.receipt, at: [80, box_height - 28], size: 9)
      pdf.text_box(plan_purchase.status.humanize, at: [80, box_height - 44], size: 10, style: :bold)
      pdf.text_box(invoice_date.strftime("%d-%m-%Y"), at: [80, box_height - 60], size: 10, style: :bold)
    end

    pdf.move_down box_height + 10
  end

  def render_plan_table(pdf)
    table_data = [["Plan", "Duration", "Payment Status", "Amount"]]
    table_data << [
      plan_purchase.plan.name,
      plan_purchase.plan.duration_label,
      plan_purchase.status.humanize,
      inr(plan_purchase.amount)
    ]

    pdf.table(table_data, header: true, width: pdf.bounds.width, cell_style: { border_color: BORDER_COLOR, padding: 8, size: 10 }) do
      row(0).font_style = :bold
      row(0).background_color = HEADER_BG
      row(0).text_color = PRIMARY_COLOR
      columns(3).align = :right
      self.row_colors = ["FFFFFF", "FCFDFC"]
    end

    pdf.move_down 14
  end

  def render_summary(pdf)
    summary_data = [
      ["Plan total", inr(plan_purchase.amount)],
      ["Currency", plan_purchase.currency],
      ["Razorpay payment", plan_purchase.razorpay_payment_id.presence || "Pending"],
      ["Final total", inr(plan_purchase.amount)]
    ]

    pdf.table(summary_data, position: :right, width: 250, cell_style: { border_color: BORDER_COLOR, padding: 7, size: 10 }) do
      columns(1).align = :right
      row(0..-2).background_color = TOTAL_BG
      row(-1).font_style = :bold
      row(-1).background_color = HEADER_BG
      row(-1).text_color = PRIMARY_COLOR
    end
  end

  def render_footer(pdf)
    pdf.move_down 20
    pdf.stroke_color BORDER_COLOR
    pdf.stroke_horizontal_rule
    pdf.move_down 8
    pdf.fill_color MUTED_TEXT_COLOR
    pdf.text "This is a system-generated invoice for a Nilam Invoice plan purchase.", size: 8, align: :center
    pdf.text "Keep this invoice for your billing and payment records.", size: 8, align: :center
    pdf.fill_color "000000"
  end

  def invoice_date
    plan_purchase.paid_at || plan_purchase.created_at
  end

  def inr(amount)
    view_context.number_to_currency(amount.to_f, unit: "₹", precision: 2)
  end
end
