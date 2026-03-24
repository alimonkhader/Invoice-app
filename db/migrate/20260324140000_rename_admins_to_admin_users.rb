class RenameAdminsToAdminUsers < ActiveRecord::Migration[8.0]
  def up
    rename_table :admins, :admin_users if table_exists?(:admins) && !table_exists?(:admin_users)
  end

  def down
    rename_table :admin_users, :admins if table_exists?(:admin_users) && !table_exists?(:admins)
  end
end
