class AddUserToInvoices < ActiveRecord::Migration[8.0]
  def change
    add_reference :invoices, :user, foreign_key: true
  end
end
