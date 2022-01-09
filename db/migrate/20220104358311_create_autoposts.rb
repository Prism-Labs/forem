class CreateAutoposts < ActiveRecord::Migration[6.1]
  def change
    create_table :autoposts do |t|
      t.boolean :archived
      t.text :body_markdown
      t.string :canonical_url
      t.string :cached_organization
      t.string :cached_tag_list
      t.string :cached_user
      t.string :cached_user_name
      t.string :cached_user_username
      t.integer :collection_id
      t.string :description
      t.datetime :edited_at
      t.float :experience_level_rating
      t.float :experience_level_rating_distribution
      t.datetime :last_experience_level_rating_at
      t.string :main_image
      t.string :main_image_background_hex_color
      t.integer :organization_id
      t.datetime :originally_published_at
      t.string :password
      t.string :path
      t.text :processed_html
      t.boolean :published
      t.datetime :published_at
      t.text :slug
      t.string :social_image
      t.string :title
      t.integer :user_id   
      t.string :video
      t.string :video_closed_caption_track_url
      t.string :video_code
      t.float :video_duration_in_seconds
      t.string :video_source_url
      t.string :video_state
      t.string :video_thumbnail_url

      t.timestamps null: false
    end

    add_foreign_key :autoposts, :users, on_delete: :cascade, validate: false
    add_foreign_key :autoposts, :organizations, on_delete: :nullify, validate: false
    add_foreign_key :autoposts, :collections, on_delete: :nullify, validate: false

    add_index :autoposts, :cached_tag_list, using: :gin, opclass: :gin_trgm_ops
    add_index("autoposts", "user_id")
    add_index("autoposts", "canonical_url", unique: true)
    add_index("autoposts", "collection_id")
    add_index("autoposts", "slug")
  end
end
