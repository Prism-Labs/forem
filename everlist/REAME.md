# Additions for [Everlist](https://everlist.org)

## Install (Self-host)

Here are some guideline: https://forem.dev/akhil/self-hosting-forem-on-digital-ocean-servers-4f0m

## Running the app

```sh
foreman start

# or 

nohup foreman start > log/foreman.log 2>&1 &
```

## Code Management

- forked from `forem/forem.git`, can be updated by fetching from upstream.
- production version is in `everlist/prod` branch
- development code is in `everlist/dev` branch
- create feature branch `everlist/feature/xxx` from `everlist/dev`

## Features

- [x]  Create 'tiktok' tag to embed tiktok videos

  ```liquid
  {% tiktok https://www.tiktok.com/@scout2015/video/6718335390845095173 %}
  ```

  Files:
  - ADDED `app/liquid_tags/tiktok_tag.rb`
  - ADDED `app/views/liquids/_tiktok.html.erb`
  - ADDED `spec/liquid_tags/tiktok_tag_spec.rb`

- [ ]  Create 'amazon' tag to embed amazon product urls

  ```liquid
  {% amazon %}
  ```

- [ ]  Find a way to include global js tags in footer for ads or google tag manager script

- [x]  When clicking on an article on the feed, popup a modal with the post view rather than redirect to the single article view.

  ```liquid
  {% tiktok https://www.tiktok.com/@scout2015/video/6718335390845095173 %}
  ```

  Files:
  - ADDED or MODIFIED `app/javascripts/articles/*`

- [x]  Create 'linkwithpreview' tag to embed url with previews. Previews will be generated using Embedly API.

  ```liquid
  {% linkwithpreview "url" %}
  ```

  Files:
  - ADDED `app/liquid_tags/link_with_preview_tag.rb`
  - ADDED `app/views/liquids/_link_with_preview.html.erb`

- [x]  Create an automated post using [Dune API](https://dune.xyz)
  Files:
  - ADDED `app/workers/everlist/dune_autopost_worker

- [] Update User Profile page to have the Crypto wallet details
  This feature is implemented using some "optional" features of Forem, which is disabled by default.
  1. `/admin/feature_flags/features`, add and enable feature named "profile_admin"
  2. `/admin/customization/profile_fields`, add profile_field_group and a new profile_field,
    named "Ethereum Address" and this field would be accessible by `user.profile.ethereum_address`

## Optional Features of Forem

Some of the optional features of Forem is enabled/disabled using Feature Flags.

`ruby

FeatureFlag.enabled?(:connect)
...

FeatureFlag.enable(:connect)
`

 The steps to enable/disable any optional feature flags are hidden in the page: `/admin/feature_flags/features`.

## Troubleshooting

- Forem source code as some git event hooks that checks and builds code on committing.
  To disable this feature, use `--no-verify` flag when commiting.
- The "live chatting" or "direct messaging" feature is enabled/disabled by "connect" feature flag, and this flag is initially disabled.

