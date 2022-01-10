class AddApprovedToAutoposts < ActiveRecord::Migration[6.1]
  def change
    add_column :autoposts, :approved, :boolean, default: false
  end
end