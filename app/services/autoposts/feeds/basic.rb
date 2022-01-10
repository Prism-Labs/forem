module Autoposts
  module Feeds
    class Basic
      def initialize(user: nil, number_of_autoposts: Autopost::DEFAULT_FEED_PAGINATION_WINDOW_SIZE, page: 1, tag: nil)
        @user = user
        @number_of_autoposts = number_of_autoposts
        @page = page
        @tag = tag
        @autopost_score_applicator = Autoposts::Feeds::AutopostScoreCalculatorForUser.new(user: @user)
      end

      def default_home_feed(**_kwargs)
        autoposts = Autopost.published
          .order(hotness_score: :desc)
          .where(score: 0..)
          .limit(@number_of_autoposts)
          .limited_column_select.includes(top_comments: :user)
        return autoposts unless @user

        autoposts = autoposts.where.not(user_id: UserBlock.cached_blocked_ids_for_blocker(@user.id))
        autoposts.sort_by.with_index do |autopost, index|
          tag_score = score_followed_tags(autopost)
          user_score = score_followed_user(autopost)
          org_score = score_followed_organization(autopost)

          # NOTE: Not quite understanding the purpose of the `-
          # index`.  My guess is that it helps reduce the impact of the
          # hotness score on the sort order.
          tag_score + org_score + user_score - index
        end.reverse!
      end

      # Alias :feed to preserve past implementations, but favoring a
      # convergence of interface implementations.
      alias feed default_home_feed

      # Creating :more_comments_minimal_weight_randomized to conform
      # to the public interface of
      # Autoposts::Feeds::LargeForemExperimental
      alias more_comments_minimal_weight_randomized default_home_feed

      delegate(:score_followed_tags,
               :score_followed_user,
               :score_followed_organization,
               to: :@autopost_score_applicator)
    end
  end
end
