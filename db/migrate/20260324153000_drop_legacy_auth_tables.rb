class DropLegacyAuthTables < ActiveRecord::Migration[8.0]
  def up
    drop_table :accounts if table_exists?(:accounts)
    drop_table :admin_users if table_exists?(:admin_users)
  end

  def down
    create_table :admin_users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_salt, null: false
      t.string :password_digest, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :admin_users, :email, unique: true

    create_table :accounts do |t|
      t.references :plan, null: false, foreign_key: true
      t.string :company_name, null: false
      t.string :owner_name, null: false
      t.string :email, null: false
      t.string :phone, null: false
      t.string :status, null: false, default: "registered"
      t.date :started_on, null: false
      t.date :expires_on
      t.integer :invoice_limit
      t.integer :plan_price, null: false, default: 0
      t.boolean :excel_reports_enabled, null: false, default: false
      t.timestamps
    end
    add_index :accounts, :email
  end
end
