module Autoposts
  class Attributes
    ATTRIBUTES = %i[archived body_markdown canonical_url description
                    edited_at main_image organization_id user_id published
                    title video_thumbnail_url].freeze

    attr_reader :attributes, :autopost_user

    def initialize(attributes, autopost_user)
      @attributes = attributes
      @autopost_user = autopost_user
    end

    def for_update(update_edited_at: false)
      hash = attributes.slice(*ATTRIBUTES)
      # don't reset the collection when no series was passed
      hash[:collection] = collection if attributes.key?(:series)
      hash[:tag_list] = tag_list
      hash[:edited_at] = Time.current if update_edited_at
      hash
    end

    private

    def collection
      Collection.find_series(attributes[:series], autopost_user) if attributes[:series].present?
    end

    def tag_list
      if attributes[:tag_list]
        attributes[:tag_list]
      elsif attributes[:tags]
        attributes[:tags].join(", ")
      end
    end
  end
end
