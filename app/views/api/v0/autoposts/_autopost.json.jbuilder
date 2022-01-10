json.type_of "autopost"

json.extract!(
  autopost,
  :id,
  :title,
  :description,
  :readable_publish_date,
  :slug,
  :path,
  :url,
  :collection_id,
  :published_timestamp,
)


json.cover_image     cloud_cover_url(autopost.main_image)
json.social_image    autopost_social_image_url(autopost)
json.canonical_url   autopost.processed_canonical_url
json.created_at      utc_iso_timestamp(autopost.created_at)
json.edited_at       utc_iso_timestamp(autopost.edited_at)
json.published_at    utc_iso_timestamp(autopost.published_at)
