class ValidateAddForeignKeyFromArticlesToAutoposts < ActiveRecord::Migration[6.1]
  def change
    validate_foreign_key :articles, :autoposts
  end
end