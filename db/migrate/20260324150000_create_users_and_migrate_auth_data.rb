class CreateUsersAndMigrateAuthData < ActiveRecord::Migration[8.0]
  def up
    create_table :users do |t|
      t.references :plan, foreign_key: true
      t.string :name, null: false
      t.string :company_name
      t.string :email, null: false
      t.string :phone
      t.string :role, null: false
      t.string :status, null: false, default: "active"
      t.date :started_on
      t.date :expires_on
      t.integer :invoice_limit
      t.integer :plan_price, null: false, default: 0
      t.boolean :excel_reports_enabled, null: false, default: false
      t.string :password_salt, null: false
      t.string :password_digest, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :role

    migrate_admin_users
    migrate_account_users
    seed_default_admin_if_missing
  end

  def down
    drop_table :users
  end

  private

  def migrate_admin_users
    return unless table_exists?(:admin_users)

    execute <<~SQL
      INSERT INTO users (name, email, phone, role, status, started_on, expires_on, invoice_limit, plan_price, excel_reports_enabled, password_salt, password_digest, active, created_at, updated_at)
      SELECT name, email, NULL, 'admin', 'active', CURRENT_DATE, NULL, NULL, 0, TRUE, password_salt, password_digest, active, created_at, updated_at
      FROM admin_users
      WHERE email NOT IN (SELECT email FROM users)
    SQL
  end

  def migrate_account_users
    return unless table_exists?(:accounts)

    account_rows = execute(<<~SQL)
      SELECT id, plan_id, owner_name, company_name, email, phone, status, started_on, expires_on, invoice_limit, plan_price, excel_reports_enabled, created_at, updated_at
      FROM accounts
      WHERE email NOT IN (SELECT email FROM users)
    SQL

    account_rows.each do |row|
      salt = SecureRandom.hex(16)
      temp_password = SecureRandom.hex(8)
      digest = Digest::SHA256.hexdigest("#{salt}--#{temp_password}")

      execute <<~SQL
        INSERT INTO users (plan_id, name, company_name, email, phone, role, status, started_on, expires_on, invoice_limit, plan_price, excel_reports_enabled, password_salt, password_digest, active, created_at, updated_at)
        VALUES (
          #{row['plan_id']},
          #{quote(row['owner_name'])},
          #{quote(row['company_name'])},
          #{quote(row['email'])},
          #{quote(row['phone'])},
          'account_admin',
          #{quote(row['status'])},
          #{quote(row['started_on'])},
          #{quote(row['expires_on'])},
          #{row['invoice_limit'].nil? ? 'NULL' : row['invoice_limit']},
          #{row['plan_price'] || 0},
          #{row['excel_reports_enabled'] ? 'TRUE' : 'FALSE'},
          #{quote(salt)},
          #{quote(digest)},
          TRUE,
          #{quote(row['created_at'])},
          #{quote(row['updated_at'])}
        )
      SQL
    end
  end

  def seed_default_admin_if_missing
    email = ENV.fetch("ADMIN_EMAIL", "admin@invoiceapp.local")
    return if select_value("SELECT 1 FROM users WHERE email = #{quote(email)} LIMIT 1")

    password = ENV.fetch("ADMIN_PASSWORD", "admin123")
    salt = SecureRandom.hex(16)
    digest = Digest::SHA256.hexdigest("#{salt}--#{password}")

    execute <<~SQL
      INSERT INTO users (name, email, role, status, plan_price, excel_reports_enabled, password_salt, password_digest, active, started_on, created_at, updated_at)
      VALUES ('Super Admin', #{quote(email)}, 'admin', 'active', 0, TRUE, #{quote(salt)}, #{quote(digest)}, TRUE, CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    SQL
  end
end
