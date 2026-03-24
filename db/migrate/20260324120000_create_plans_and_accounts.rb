class CreatePlansAndAccounts < ActiveRecord::Migration[8.0]
  def up
    create_table :plans do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.integer :price, null: false, default: 0
      t.integer :invoice_limit
      t.integer :duration_months, null: false, default: 0
      t.boolean :excel_reports, null: false, default: false
      t.text :description
      t.boolean :active, null: false, default: true
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_index :plans, :code, unique: true

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

    execute <<~SQL
      INSERT INTO plans (name, code, price, invoice_limit, duration_months, excel_reports, description, active, position, created_at, updated_at)
      VALUES
        ('Trial', 'trial', 0, 25, 0, FALSE, 'Free plan with 25 invoices.', TRUE, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
        ('Basic', 'basic', 299, NULL, 1, FALSE, 'One month plan with unlimited invoices.', TRUE, 2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
        ('Premium', 'premium', 499, NULL, 3, TRUE, 'Three month plan with unlimited invoices and Excel report export.', TRUE, 3, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    SQL
  end

  def down
    drop_table :accounts
    drop_table :plans
  end
end
