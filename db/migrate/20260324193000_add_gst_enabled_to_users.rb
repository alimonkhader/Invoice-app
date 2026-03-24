class AddGstEnabledToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :gst_enabled, :boolean, default: true, null: false
  end
end
