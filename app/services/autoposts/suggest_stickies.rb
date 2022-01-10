module Autoposts
  class SuggestStickies
    SUGGESTION_TAGS = %w[career productivity discuss explainlikeimfive].freeze

    def self.call(autopost)
      new(autopost).call
    end

    def initialize(autopost)
      @autopost = autopost
      @reaction_count_num = Rails.env.production? ? 15 : -1
      @comment_count_num = Rails.env.production? ? 7 : -2
    end

    def call
      (tag_autoposts.load + more_autoposts).sample(3)
    end

    private

    attr_accessor :autopost, :reaction_count_num, :comment_count_num

    def tag_autoposts
      autopost_tags = autopost.cached_tag_list_array - ["discuss"]

      Autopost
        .published
        .tagged_with(autopost_tags, any: true).unscope(:select)
        .limited_column_select
        .where("public_reactions_count > ? OR comments_count > ?", reaction_count_num, comment_count_num)
        .where.not(id: autopost.id)
        .where.not(user_id: autopost.user_id)
        .where("featured_number > ?", 5.days.ago.to_i)
        .order(Arel.sql("RANDOM()"))
        .limit(3)
    end

    def more_autoposts
      return [] if tag_autoposts.size > 6

      Autopost
        .published
        .tagged_with(SUGGESTION_TAGS, any: true).unscope(:select)
        .limited_column_select
        .where("comments_count > ?", comment_count_num)
        .where.not(id: autopost.id)
        .where.not(user_id: autopost.user_id)
        .where("featured_number > ?", 5.days.ago.to_i)
        .order(Arel.sql("RANDOM()"))
        .limit(10 - tag_autoposts.size)
    end
  end
end
