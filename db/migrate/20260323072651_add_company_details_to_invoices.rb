class AddCompanyDetailsToInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :invoices, :company_name, :string
    add_column :invoices, :address, :string
    add_column :invoices, :phone, :string
  end
end
