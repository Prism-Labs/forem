class AddColumnsToAutoposts < ActiveRecord::Migration[6.1]
  def change
    add_column :autoposts, :last_article_created_at, :datetime
    add_column :autoposts, :last_article_updated_at, :datetime
    add_column :autoposts, :last_article_id, :bigint
  end
end
