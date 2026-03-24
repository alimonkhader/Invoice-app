class CreateInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :invoices do |t|
      t.string :invoice_number
      t.date :date
      t.references :customer, null: false, foreign_key: true
      t.decimal :total

      t.timestamps
    end
  end
end
