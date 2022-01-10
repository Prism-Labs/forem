module Autoposts
  module Feeds
    module Timeframe
      def self.call(timeframe, tag: nil, number_of_autoposts: Autopost::DEFAULT_FEED_PAGINATION_WINDOW_SIZE, page: 1)
        autoposts = ::Autoposts::Feeds::Tag.call(tag)

        autoposts
          .where("published_at > ?", ::Timeframe.datetime(timeframe))
          .order(score: :desc)
          .page(page)
          .per(number_of_autoposts)
      end
    end
  end
end
