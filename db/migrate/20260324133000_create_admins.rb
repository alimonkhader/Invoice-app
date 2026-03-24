class CreateAdmins < ActiveRecord::Migration[8.0]
  def up
    create_table :admins do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_salt, null: false
      t.string :password_digest, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    add_index :admins, :email, unique: true

    email = ENV.fetch("ADMIN_EMAIL", "admin@invoiceapp.local")
    password = ENV.fetch("ADMIN_PASSWORD", "admin123")
    salt = SecureRandom.hex(16)
    digest = Digest::SHA256.hexdigest("#{salt}--#{password}")

    execute <<~SQL
      INSERT INTO admins (name, email, password_salt, password_digest, active, created_at, updated_at)
      VALUES ('Super Admin', #{quote(email)}, #{quote(salt)}, #{quote(digest)}, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    SQL
  end

  def down
    drop_table :admins
  end
end
