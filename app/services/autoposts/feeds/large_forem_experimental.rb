module Autoposts
  module Feeds
    class LargeForemExperimental
      def initialize(user: nil, number_of_autoposts: Autopost::DEFAULT_FEED_PAGINATION_WINDOW_SIZE, page: 1, tag: nil)
        @user = user
        @number_of_autoposts = number_of_autoposts
        @page = page
        @tag = tag
        @autopost_score_applicator = Autoposts::Feeds::AutopostScoreCalculatorForUser.new(user: user)
      end

      def default_home_feed(user_signed_in: false)
        _featured_story, stories = featured_story_and_default_home_feed(user_signed_in: user_signed_in, ranking: true)
        stories
      end

      # @param user_signed_in [Boolean] are we treating this as an
      #        anonymous user?
      # @param ranking [Boolean] if true, apply a ranking algorithm
      # @param must_have_main_image [Boolean] if true, the featured
      #        story must have a main image
      #
      # @note the must_have_main_image parameter name matches PR #15240
      def featured_story_and_default_home_feed(user_signed_in: false, ranking: true, must_have_main_image: true)
        featured_story, hot_stories = globally_hot_autoposts(user_signed_in, must_have_main_image: must_have_main_image)
        hot_stories = rank_and_sort_autoposts(hot_stories) if @user && ranking
        [featured_story, hot_stories]
      end

      # Adding an alias to preserve public method signature.
      # Eventually, we should be able to remove the alias.
      alias default_home_feed_and_featured_story featured_story_and_default_home_feed

      def more_comments_minimal_weight_randomized
        _featured_story, stories = featured_story_and_default_home_feed(user_signed_in: true)
        first_quarter(stories).shuffle + last_three_quarters(stories)
      end

      # Adding an alias to preserve public method signature.  However,
      # in this code base there are no further references of
      # :more_comments_minimal_weight_randomized_at_end
      alias more_comments_minimal_weight_randomized_at_end more_comments_minimal_weight_randomized

      # @api private
      def rank_and_sort_autoposts(autoposts)
        ranked_autoposts = autoposts.each_with_object({}) do |autopost, result|
          autopost_points = score_single_autopost(autopost)
          result[autopost] = autopost_points
        end
        ranked_autoposts = ranked_autoposts.sort_by { |_autopost, autopost_points| -autopost_points }.map(&:first)
        ranked_autoposts.to(@number_of_autoposts - 1)
      end

      # @api private
      def score_single_autopost(autopost, base_autopost_points: 0)
        autopost_points = base_autopost_points
        autopost_points += score_followed_user(autopost)
        autopost_points += score_followed_organization(autopost)
        autopost_points += score_followed_tags(autopost)
        autopost_points += score_experience_level(autopost)
        autopost_points += score_comments(autopost)
        autopost_points
      end

      delegate(:score_followed_user,
               :score_followed_tags,
               :score_followed_organization,
               :score_experience_level,
               :score_comments,
               to: :@autopost_score_applicator)

      # @api private
      # rubocop:disable Layout/LineLength
      def globally_hot_autoposts(user_signed_in, must_have_main_image: true, autopost_score_threshold: -15, min_rand_limit: 15, max_rand_limit: 80)
        # rubocop:enable Layout/LineLength
        if user_signed_in
          hot_stories = experimental_hot_story_grab
          hot_stories = hot_stories.where.not(user_id: UserBlock.cached_blocked_ids_for_blocker(@user.id))
          featured_story = featured_story_from(stories: hot_stories, must_have_main_image: must_have_main_image)
          new_stories = Autopost.published
            .where("score > ?", autopost_score_threshold)
            .limited_column_select.includes(top_comments: :user).order(published_at: :desc)
            .limit(rand(min_rand_limit..max_rand_limit))
          hot_stories = hot_stories.to_a + new_stories.to_a
        else
          hot_stories = Autopost.published.limited_column_select
            .page(@page).per(@number_of_autoposts)
            .where("score >= ? OR featured = ?", Settings::UserExperience.home_feed_minimum_score, true)
            .order(hotness_score: :desc)
          featured_story = featured_story_from(stories: hot_stories, must_have_main_image: must_have_main_image)
        end
        [featured_story, hot_stories.to_a]
      end

      private

      def featured_story_from(stories:, must_have_main_image:)
        return stories.first unless must_have_main_image

        stories.where.not(main_image: nil).first
      end

      def experimental_hot_story_grab
        start_time = Autoposts::Feeds.oldest_published_at_to_consider_for(user: @user)
        Autopost.published.limited_column_select.includes(top_comments: :user)
          .where("published_at > ?", start_time)
          .page(@page).per(@number_of_autoposts)
          .order(score: :desc)
      end

      def first_quarter(array)
        array[0...(array.length / 4)]
      end

      def last_three_quarters(array)
        array[(array.length / 4)..array.length]
      end
    end
  end
end
