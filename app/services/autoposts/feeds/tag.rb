module Autoposts
  module Feeds
    module Tag
      def self.call(tag = nil, number_of_autoposts: Autopost::DEFAULT_FEED_PAGINATION_WINDOW_SIZE, page: 1)
        autoposts =
          if tag.present?
            if FeatureFlag.enabled?(:optimize_autopost_tag_query)
              Autopost.cached_tagged_with_any(tag)
            else
              ::Tag.find_by(name: tag).autoposts
            end
          else
            Autopost.all
          end

        autoposts
          .published
          .limited_column_select
          .includes(top_comments: :user)
          .page(page)
          .per(number_of_autoposts)
      end
    end
  end
end
