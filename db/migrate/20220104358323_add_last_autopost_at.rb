class AddLastAutopostAt < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :last_autopost_at, :datetime, default: "2017-01-01 05:00:00"
    add_column :organizations, :last_autopost_at, :datetime, default: "2017-01-01 05:00:00"
  end
end