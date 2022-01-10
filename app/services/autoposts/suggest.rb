module Autoposts
  class Suggest
    MAX_DEFAULT = 4

    def self.call(autopost, max: MAX_DEFAULT)
      new(autopost, max: max).call
    end

    def initialize(autopost, max: MAX_DEFAULT)
      @autopost = autopost
      @max = max
      @total_autoposts_count = Autopost.published.estimated_count
    end

    def call
      if cached_tag_list_array.any?
        # avoid loading more data if we don't need to
        tagged_suggestions = suggestions_by_tag(max: max)
        return tagged_suggestions if tagged_suggestions.size == max

        # if there are not enough tagged autoposts, load other suggestions
        # ignoring tagged autoposts that might be relevant twice, hence avoiding duplicates
        num_remaining_needed = max - tagged_suggestions.size
        other_autoposts = other_suggestions(
          max: num_remaining_needed,
          ids_to_ignore: tagged_suggestions.map(&:id),
        )
        tagged_suggestions.union(other_autoposts)
      else
        other_suggestions
      end
    end

    private

    attr_reader :autopost, :max, :total_autoposts_count

    def other_suggestions(max: MAX_DEFAULT, ids_to_ignore: [])
      ids_to_ignore << autopost.id
      Autopost.published
        .where.not(id: ids_to_ignore)
        .where.not(user_id: autopost.user_id)
        .order(hotness_score: :desc)
        .offset(rand(0..offset))
        .first(max)
    end

    def suggestions_by_tag(max: MAX_DEFAULT)
      Autopost
        .published
        .cached_tagged_with_any(cached_tag_list_array)
        .where.not(user_id: autopost.user_id)
        .where(tag_suggestion_query)
        .order(hotness_score: :desc)
        .offset(rand(0..offset))
        .first(max)
    end

    def offset
      total_autoposts_count > 1000 ? 200 : (total_autoposts_count / 10)
    end

    def tag_suggestion_query
      # Fore big communities like DEV we can look at organic page views for indicator.
      # For smaller communities, we'll a basic score check.
      total_autoposts_count > 1000 ? "organic_page_views_past_month_count > 5" : "score > 1"
    end

    def cached_tag_list_array
      (autopost.cached_tag_list || "").split(", ")
    end
  end
end
