json.array! @autoposts do |autopost|
  json.extract!(
    autopost,
    :id,
    :title,
    :description,
    :published_at,
    :comments_count,
    :public_reactions_count,
  )

  json.tag_list autopost.cached_tag_list

  json.user do
    json.name              autopost.user.name
    json.profile_image_url Images::Profile.call(autopost.user.profile_image_url, length: 90)
  end
end
