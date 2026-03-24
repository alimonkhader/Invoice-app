class CreateInvoiceItems < ActiveRecord::Migration[8.0]
  def change
    create_table :invoice_items do |t|
      t.string :name
      t.integer :quantity
      t.decimal :price
      t.references :invoice, null: false, foreign_key: true

      t.timestamps
    end
  end
end
