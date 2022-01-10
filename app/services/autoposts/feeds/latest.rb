module Autoposts
  module Feeds
    module Latest
      MINIMUM_SCORE = -20

      def self.call(tag: nil, number_of_autoposts: Autopost::DEFAULT_FEED_PAGINATION_WINDOW_SIZE, page: 1)
        Autoposts::Feeds::Tag.call(tag)
          .order(published_at: :desc)
          .where("score > ?", MINIMUM_SCORE)
          .page(page)
          .per(number_of_autoposts)
      end
    end
  end
end
