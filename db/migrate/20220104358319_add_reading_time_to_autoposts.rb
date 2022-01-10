class AddReadingTimeToAutoposts < ActiveRecord::Migration[6.1]
  def change
    add_column :autoposts, :reading_time, :integer, default: 0
  end
end