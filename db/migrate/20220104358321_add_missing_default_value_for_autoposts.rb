class AddMissingDefaultValueForAutoposts < ActiveRecord::Migration[6.1]
  def change
    change_column :autoposts, :main_image_background_hex_color, :string, default: "#dddddd"
  end
end