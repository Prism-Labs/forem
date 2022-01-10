json.array! @autoposts do |autopost|
  json.type_of "autopost"

  json.extract!(
    autopost,
    :id, :title, :description, :published, :published_at,
    :slug, :path, :url, :comments_count, :public_reactions_count, :page_views_count,
    :published_timestamp, :body_markdown
  )

  json.positive_reactions_count autopost.public_reactions_count
  json.cover_image              cloud_cover_url(autopost.main_image)
  json.tag_list                 autopost.cached_tag_list_array
  json.canonical_url            autopost.processed_canonical_url

  json.partial! "api/v0/shared/user", user: autopost.user

  if autopost.organization
    json.partial! "api/v0/shared/organization", organization: autopost.organization
  end

  flare_tag = FlareTag.new(autopost).tag
  if flare_tag
    json.partial! "flare_tag", flare_tag: flare_tag
  end
end
