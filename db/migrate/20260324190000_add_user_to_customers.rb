class AddUserToCustomers < ActiveRecord::Migration[8.0]
  def change
    add_reference :customers, :user, foreign_key: true
  end
end
