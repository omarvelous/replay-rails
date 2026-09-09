class AddDeviceFieldsToPlayers < ActiveRecord::Migration[8.1]
  def change
    add_column :players, :device_type, :string
    add_column :players, :device_name, :string
    add_column :players, :device_model, :string
    add_column :players, :device_manufacturer, :string
    add_column :players, :os_name, :string
    add_column :players, :os_version, :string
    add_column :players, :app_version, :string
    add_column :players, :browser_name, :string
    add_column :players, :browser_version, :string
    add_column :players, :screen_width, :integer
    add_column :players, :screen_height, :integer
    add_column :players, :touch_capable, :boolean, default: false

    add_index :players, :device_type
  end
end
