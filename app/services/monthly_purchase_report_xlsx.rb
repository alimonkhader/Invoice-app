require "cgi"
require "zip"

class MonthlyPurchaseReportXlsx
  def initialize(month:, summary:, daily_breakdown:)
    @month = month
    @summary = summary
    @daily_breakdown = daily_breakdown
  end

  def render
    buffer = Zip::OutputStream.write_buffer do |zip|
      zip.put_next_entry("[Content_Types].xml")
      zip.write(content_types_xml)

      zip.put_next_entry("_rels/.rels")
      zip.write(root_rels_xml)

      zip.put_next_entry("xl/workbook.xml")
      zip.write(workbook_xml)

      zip.put_next_entry("xl/_rels/workbook.xml.rels")
      zip.write(workbook_rels_xml)

      zip.put_next_entry("xl/styles.xml")
      zip.write(styles_xml)

      zip.put_next_entry("xl/worksheets/sheet1.xml")
      zip.write(sheet_xml)
    end

    buffer.string
  end

  private

  attr_reader :month, :summary, :daily_breakdown

  def content_types_xml
    <<~XML
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
        <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
        <Default Extension="xml" ContentType="application/xml"/>
        <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
        <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
        <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
      </Types>
    XML
  end

  def root_rels_xml
    <<~XML
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
      </Relationships>
    XML
  end

  def workbook_xml
    <<~XML
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
        <sheets>
          <sheet name="Monthly Purchase" sheetId="1" r:id="rId1"/>
        </sheets>
      </workbook>
    XML
  end

  def workbook_rels_xml
    <<~XML
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
        <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
      </Relationships>
    XML
  end

  def styles_xml
    <<~XML
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
        <fonts count="2">
          <font>
            <sz val="11"/>
            <name val="Calibri"/>
          </font>
          <font>
            <b/>
            <sz val="11"/>
            <name val="Calibri"/>
          </font>
        </fonts>
        <fills count="2">
          <fill><patternFill patternType="none"/></fill>
          <fill><patternFill patternType="gray125"/></fill>
        </fills>
        <borders count="1">
          <border><left/><right/><top/><bottom/><diagonal/></border>
        </borders>
        <cellStyleXfs count="1">
          <xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>
        </cellStyleXfs>
        <cellXfs count="3">
          <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
          <xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/>
          <xf numFmtId="4" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>
        </cellXfs>
        <cellStyles count="1">
          <cellStyle name="Normal" xfId="0" builtinId="0"/>
        </cellStyles>
      </styleSheet>
    XML
  end

  def sheet_xml
    <<~XML
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
        <sheetViews>
          <sheetView workbookViewId="0"/>
        </sheetViews>
        <sheetFormatPr defaultRowHeight="15"/>
        <cols>
          <col min="1" max="1" width="20" customWidth="1"/>
          <col min="2" max="5" width="18" customWidth="1"/>
        </cols>
        <sheetData>
          #{sheet_rows_xml}
        </sheetData>
      </worksheet>
    XML
  end

  def sheet_rows_xml
    rows = []
    row_index = 1

    rows << inline_row(row_index, [[1, "Monthly Purchase Report", 1]])
    row_index += 1
    rows << inline_row(row_index, [[1, month.strftime("%B %Y"), 0]])
    row_index += 2

    rows << inline_row(row_index, [[1, "Summary", 1]])
    row_index += 1
    rows << inline_row(row_index, [[1, "Month", 1], [2, month.strftime("%B %Y"), 0]])
    row_index += 1
    rows << mixed_row(row_index, [[1, "Purchase Total", :string, 1], [2, summary[:purchase_total], :number, 2]])
    row_index += 1
    rows << mixed_row(row_index, [[1, "CGST", :string, 1], [2, summary[:cgst_total], :number, 2]])
    row_index += 1
    rows << mixed_row(row_index, [[1, "SGST", :string, 1], [2, summary[:sgst_total], :number, 2]])
    row_index += 1
    rows << mixed_row(row_index, [[1, "GST Total", :string, 1], [2, summary[:gst_total], :number, 2]])
    row_index += 2

    rows << inline_row(row_index, [[1, "Daily Breakdown", 1]])
    row_index += 1
    rows << inline_row(row_index, [[1, "Day", 1], [2, "Purchase Total", 1], [3, "CGST", 1], [4, "SGST", 1], [5, "GST Total", 1]])
    row_index += 1

    daily_breakdown.each do |day, totals|
      rows << mixed_row(row_index, [
        [1, day.strftime("%d %b %Y"), :string, 0],
        [2, totals[:purchase_total], :number, 2],
        [3, totals[:cgst_total], :number, 2],
        [4, totals[:sgst_total], :number, 2],
        [5, totals[:gst_total], :number, 2]
      ])
      row_index += 1
    end

    rows.join
  end

  def inline_row(index, cells)
    content = cells.map do |column, value, style|
      ref = cell_ref(column, index)
      %(<c r="#{ref}" t="inlineStr" s="#{style}"><is><t>#{escape(value)}</t></is></c>)
    end.join
    %(<row r="#{index}">#{content}</row>)
  end

  def mixed_row(index, cells)
    content = cells.map do |column, value, type, style|
      ref = cell_ref(column, index)
      if type == :number
        %(<c r="#{ref}" s="#{style}"><v>#{format_number(value)}</v></c>)
      else
        %(<c r="#{ref}" t="inlineStr" s="#{style}"><is><t>#{escape(value)}</t></is></c>)
      end
    end.join
    %(<row r="#{index}">#{content}</row>)
  end

  def cell_ref(column, row)
    "#{column_letter(column)}#{row}"
  end

  def column_letter(index)
    ("A".ord + index - 1).chr
  end

  def format_number(value)
    format("%.2f", value.to_d)
  end

  def escape(value)
    CGI.escapeHTML(value.to_s)
  end
end
