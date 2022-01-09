class AddForeignKeyFromArticlesToAutoposts < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_foreign_key :articles, :autoposts, on_delete: :nullify, validate: false
  end
end
