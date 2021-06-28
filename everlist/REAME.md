# Additions for [Everlist](https://everlist.org)

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
