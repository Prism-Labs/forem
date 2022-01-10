class AddAutopostsCountToArticlesAndOrganizations < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :autoposts_count, :integer, null: false, default: 0
    add_column :organizations, :autoposts_count, :integer, null: false, default: 0
  end
end