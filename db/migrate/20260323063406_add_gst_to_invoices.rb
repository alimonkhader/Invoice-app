class AddGstToInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :invoices, :cgst, :decimal
    add_column :invoices, :sgst, :decimal
    add_column :invoices, :final_total, :decimal
  end
end
