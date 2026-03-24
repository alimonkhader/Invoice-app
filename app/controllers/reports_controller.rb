class ReportsController < ApplicationController
  before_action :require_account_authentication
  before_action :require_excel_reports_access, only: :monthly_purchases_xlsx

  def purchases
    @selected_date = parse_selected_date
    @selected_month = parse_selected_month
    load_purchase_report_data
  end

  def monthly_purchases_xlsx
    @selected_month = parse_selected_month
    load_purchase_report_data

    send_data(
      MonthlyPurchaseReportXlsx.new(
        month: @selected_month,
        summary: {
          purchase_total: @monthly_total,
          cgst_total: @monthly_cgst_total,
          sgst_total: @monthly_sgst_total,
          gst_total: @monthly_gst_total
        },
        daily_breakdown: @monthly_daily_breakdown
      ).render,
      filename: "monthly_purchase_report_#{@selected_month.strftime('%Y_%m')}.xlsx",
      type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      disposition: "attachment"
    )
  end

  private

  def load_purchase_report_data
    invoice_rows = current_account_user.invoices.order(:date, :created_at).pluck(
      Arel.sql("COALESCE(invoices.date, DATE(invoices.created_at))"),
      :final_total,
      :cgst,
      :sgst,
      :invoice_number,
      :id,
      :company_name
    )

    @daily_rows = invoice_rows.select { |invoice_date, *_| invoice_date == @selected_date } if defined?(@selected_date)
    @daily_total = sum_final_totals(@daily_rows || [])
    @daily_cgst_total = sum_cgst_totals(@daily_rows || [])
    @daily_sgst_total = sum_sgst_totals(@daily_rows || [])
    @daily_gst_total = sum_gst_totals(@daily_rows || [])
    @daily_invoice_count = (@daily_rows || []).size

    month_range = @selected_month.beginning_of_month..@selected_month.end_of_month
    @monthly_rows = invoice_rows.select { |invoice_date, *_| month_range.cover?(invoice_date) }
    @monthly_total = sum_final_totals(@monthly_rows)
    @monthly_cgst_total = sum_cgst_totals(@monthly_rows)
    @monthly_sgst_total = sum_sgst_totals(@monthly_rows)
    @monthly_gst_total = sum_gst_totals(@monthly_rows)
    @monthly_invoice_count = @monthly_rows.size

    @monthly_daily_breakdown = @monthly_rows
      .group_by(&:first)
      .transform_values do |rows|
        {
          purchase_total: sum_final_totals(rows),
          cgst_total: sum_cgst_totals(rows),
          sgst_total: sum_sgst_totals(rows),
          gst_total: sum_gst_totals(rows)
        }
      end
      .sort_by { |date, _| date }
      .reverse

    @monthwise_tally = invoice_rows
      .group_by { |invoice_date, *_| invoice_date.beginning_of_month }
      .transform_values do |rows|
        {
          purchase_total: sum_final_totals(rows),
          cgst_total: sum_cgst_totals(rows),
          sgst_total: sum_sgst_totals(rows),
          gst_total: sum_gst_totals(rows)
        }
      end
      .sort_by { |month, _| month }
      .reverse
  end

  def parse_selected_date
    Date.parse(params[:date])
  rescue ArgumentError, TypeError
    Date.current
  end

  def parse_selected_month
    Date.strptime(params[:month], "%Y-%m")
  rescue ArgumentError, TypeError
    Date.current.beginning_of_month
  end

  def sum_final_totals(rows)
    rows.sum { |_, final_total, *| final_total.to_d }.round(2)
  end

  def sum_cgst_totals(rows)
    rows.sum { |_, _, cgst, *| cgst.to_d }.round(2)
  end

  def sum_sgst_totals(rows)
    rows.sum { |_, _, _, sgst, *| sgst.to_d }.round(2)
  end

  def sum_gst_totals(rows)
    rows.sum { |_, _, cgst, sgst, *| cgst.to_d + sgst.to_d }.round(2)
  end
end
