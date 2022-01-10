class AddDescriptiveCronAttrsToAutoposts < ActiveRecord::Migration[6.1]
  def change
    add_column :autoposts, :article_create_freq, :string, default: "daily" # every day at 00:00
    add_column :autoposts, :article_update_freq, :string, default: "daily" # every day at 23:55 before new article is posted
  end
end
