class CreateCryptoProfiles < ActiveRecord::Migration[6.1]
  def change
    create_table :crypto_profiles do |t|
      t.string "email", null: true
      t.string "twitter_username", null: true
      t.string "github_username", null: true
      t.string "ethereum_address", null: true
      t.string "web3_username", null: true
      t.string "ens", null: true
      t.string "website_url", null: true
      t.string "name", null: true
      t.string "description", null: true
      t.string "profile_image_url", nul: true
      t.integer :user_id, null: true
      t.timestamps
    end

    add_foreign_key :crypto_profiles, :users, on_delete: :nullify, validate: false
    add_index :crypto_profiles, :email
    add_index :crypto_profiles, :twitter_username
    add_index :crypto_profiles, :github_username
    add_index :crypto_profiles, :ethereum_address
    add_index :crypto_profiles, :web3_username
    add_index :crypto_profiles, :ens
    add_index :crypto_profiles, :website_url
  end
end
