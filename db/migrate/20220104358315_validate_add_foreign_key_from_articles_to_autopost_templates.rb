class ValidateAddForeignKeyFromArticlesToAutopostTemplates < ActiveRecord::Migration[6.1]
  def change
    validate_foreign_key :articles, :autopost_templates
  end
end