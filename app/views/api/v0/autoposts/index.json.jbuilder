json.array! @autoposts do |autopost|
  json.partial! "api/v0/autoposts/autopost", autopost: autopost

  # /api/autoposts and /api/autoposts/:id have opposite representations
  # of `tag_list` and `tags and we can't align them without breaking the API,
  # this is fully documented in the API docs
  # see <https://github.com/thepracticaldev/dev.to/issues/4206> for more details
  json.tag_list autopost.cached_tag_list_array
  json.tags autopost.cached_tag_list

  json.partial! "api/v0/shared/user", user: autopost.user

  if autopost.organization
    json.partial! "api/v0/shared/organization", organization: autopost.organization
  end

  flare_tag = FlareTag.new(autopost).tag
  if flare_tag
    json.partial! "api/v0/autoposts/flare_tag", flare_tag: flare_tag
  end
end
