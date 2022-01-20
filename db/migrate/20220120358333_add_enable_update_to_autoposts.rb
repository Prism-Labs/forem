class AddEnableUpdateToAutoposts < ActiveRecord::Migration[6.1]
  def change
    add_column :autoposts, :enable_update, :boolean, default: false
  end
end
