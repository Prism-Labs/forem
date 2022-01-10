module Autoposts
  class GetUserStickies
    def self.call(autopost, author)
      autopost_tags = autopost.cached_tag_list_array - ["discuss"]

      author
        .autoposts
        .published
        .cached_tagged_with_any(autopost_tags)
        .unscope(:select)
        .limited_column_select
        .where.not(id: autopost.id)
        .order(published_at: :desc)
        .limit(3)
    end
  end
end
