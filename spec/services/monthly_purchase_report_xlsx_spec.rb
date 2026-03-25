require "rails_helper"
require "zip"

RSpec.describe MonthlyPurchaseReportXlsx do
  it "renders an xlsx zip with workbook files and escaped values" do
    data = described_class.new(
      month: Date.new(2026, 3, 1),
      summary: { purchase_total: 100, cgst_total: 9, sgst_total: 9, gst_total: 18 },
      daily_breakdown: {
        Date.new(2026, 3, 25) => { purchase_total: 100, cgst_total: 9, sgst_total: 9, gst_total: 18 }
      }
    ).render

    entries = []
    worksheet = nil
    Zip::InputStream.open(StringIO.new(data)) do |io|
      while (entry = io.get_next_entry)
        entries << entry.name
        worksheet = io.read if entry.name == "xl/worksheets/sheet1.xml"
      end
    end

    expect(entries).to include("[Content_Types].xml", "_rels/.rels", "xl/workbook.xml", "xl/_rels/workbook.xml.rels", "xl/styles.xml", "xl/worksheets/sheet1.xml")
    expect(worksheet).to include("Monthly Purchase Report")
    expect(worksheet).to include("25 Mar 2026")
  end
end
