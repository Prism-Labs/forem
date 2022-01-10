class Autopost < ApplicationRecord
  include CloudinaryHelper
  include ActionView::Helpers
  include Storext.model
  include Reactable

  acts_as_taggable_on :tags
  resourcify

  include StringAttributeCleaner.for(:canonical_url, on: :before_save)
  DEFAULT_FEED_PAGINATION_WINDOW_SIZE = 50

  attr_accessor :publish_under_org
  attr_writer :series

  delegate :name, to: :user, prefix: true
  delegate :username, to: :user, prefix: true

  # touch: true was removed because when an article is updated, the associated collection
  # is touched along with all its articles(including this one). This causes eventually a deadlock.
  belongs_to :collection, optional: true

  belongs_to :organization, optional: true
  belongs_to :user

  counter_culture :user
  counter_culture :organization

  # The date that we began limiting the number of user mentions in an article.
  MAX_USER_MENTION_LIVE_AT = Time.utc(2021, 4, 7).freeze
  UNIQUE_URL_ERROR = "has already been taken. " \
                     "Email #{ForemInstance.email} for further details.".freeze

  has_many :articles, dependent: :nullify

  validates :body_markdown, bytesize: { maximum: 800.kilobytes, too_long: "is too long." }
  validates :body_markdown, length: { minimum: 0, allow_nil: false }
  validates :body_markdown, uniqueness: { scope: %i[user_id title] }

  validates :main_image, url: { allow_blank: true, schemes: %w[https http] }
  validates :main_image_background_hex_color, format: /\A#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/
  validates :slug, presence: { if: :published? }, format: /\A[0-9a-z\-_]*\z/
  validates :slug, uniqueness: { scope: :user_id }
  validates :title, presence: true, length: { maximum: 128 }
  validates :user_id, presence: true
  validates :video, url: { allow_blank: true, schemes: %w[https http] }
  validates :video_closed_caption_track_url, url: { allow_blank: true, schemes: ["https"] }
  validates :video_source_url, url: { allow_blank: true, schemes: ["https"] }
  validates :video_source_url, url: { allow_blank: true, schemes: ["https"] }
  validates :video_state, inclusion: { in: %w[PROGRESSING COMPLETED] }, allow_nil: true
  validates :video_thumbnail_url, url: { allow_blank: true, schemes: %w[https http] }

  validate :canonical_url_must_not_have_spaces
  validate :past_or_present_date
  validate :validate_collection_permission
  validate :validate_tag
  validate :validate_video

  before_validation :evaluate_markdown, :create_slug
  before_save :set_all_dates

  before_save :fetch_video_duration
  before_save :set_caches
  before_create :create_password
  before_destroy :before_destroy_actions, prepend: true

  after_save :bust_cache


  # [@jgaskins] We use an index on `published`, but since it's a boolean value
  #   the Postgres query planner often skips it due to lack of diversity of the
  #   data in the column. However, since `published_at` is a *very* diverse
  #   column and can scope down the result set significantly, the query planner
  #   can make heavy use of it.
  scope :published, lambda {
    where(published: true)
      .where("published_at <= ?", Time.current)
  }
  scope :unpublished, -> { where(published: false) }

  scope :admin_published_with, lambda { |tag_name|
    published
      .where(user_id: User.with_role(:super_admin)
                          .union(User.with_role(:admin))
                          .union(id: [Settings::Community.staff_user_id,
                                      Settings::General.mascot_user_id].compact)
                          .select(:id)).order(published_at: :desc).tagged_with(tag_name)
  }

  scope :user_published_with, lambda { |user_id, tag_name|
    published
      .where(user_id: user_id)
      .order(published_at: :desc)
      .tagged_with(tag_name)
  }

  scope :active_help, lambda {
    stories = published.cached_tagged_with("help").order(created_at: :desc)

    stories.where(published_at: 12.hours.ago..).presence || stories
  }

  scope :limited_column_select, lambda {
    select(:path, :title, :id, :published,
           :main_image, :main_image_background_hex_color, :updated_at, :slug,
           :video, :user_id, :organization_id, :video_source_url, :video_code,
           :video_thumbnail_url, :video_closed_caption_track_url,
           :experience_level_rating, :experience_level_rating_distribution, :cached_user, :cached_organization,
           :published_at, :description, :video_duration_in_seconds)
  }

  scope :limited_columns_internal_select, lambda {
    select(:path, :title, :id, :published,
           :main_image, :main_image_background_hex_color, :updated_at,
           :video, :user_id, :organization_id, :video_source_url, :video_code,
           :video_thumbnail_url, :video_closed_caption_track_url, :social_image,
           :published_at, :created_at, :body_markdown, :processed_html)
  }

  scope :sorting, lambda { |value|
    value ||= "creation-desc"
    kind, dir = value.split("-")

    dir = "desc" unless %w[asc desc].include?(dir)

    column =
      case kind
      when "creation"  then :created_at
      when "published" then :published_at
      else
        :created_at
      end

    order(column => dir.to_sym)
  }

  scope :feed, lambda {
                 published.includes(:taggings)
                   .select(
                     :id, :published_at, :processed_html, :user_id, :organization_id, :title, :path, :cached_tag_list
                   )
               }

  scope :with_video, lambda {
                       published
                         .where.not(video: [nil, ""])
                         .where.not(video_thumbnail_url: [nil, ""])
                     }

  scope :eager_load_serialized_data, -> { includes(:user, :organization, :tags) }

  def search_id
    "article_#{id}"
  end

  def processed_description
    if body_text.present?
      body_text
        .truncate(104, separator: " ")
        .tr("\n", " ")
        .strip
    else
      "A post by #{user.name}"
    end
  end

  def body_text
    ActionView::Base.full_sanitizer.sanitize(processed_html)[0..7000]
  end

  def username
    return organization.slug if organization

    user.username
  end

  def current_state_path
    published ? "/#{username}/#{slug}" : "/#{username}/#{slug}?preview=#{password}"
  end

  def has_frontmatter?
    fixed_body_markdown = MarkdownProcessor::Fixer::FixAll.call(body_markdown)
    begin
      parsed = FrontMatterParser::Parser.new(:md).call(fixed_body_markdown)
      parsed.front_matter["title"].present?
    rescue Psych::SyntaxError, Psych::DisallowedClass
      # if frontmatter is invalid, still render editor with errors instead of 500ing
      true
    end
  end

  def class_name
    self.class.name
  end

  def flare_tag
    @flare_tag ||= FlareTag.new(self).tag_hash
  end

  def edited?
    edited_at.present?
  end

  def readable_edit_date
    return unless edited?

    if edited_at.year == Time.current.year
      edited_at.strftime("%b %e")
    else
      edited_at.strftime("%b %e '%y")
    end
  end

  def readable_publish_date
    relevant_date = displayable_published_at
    if relevant_date && relevant_date.year == Time.current.year
      relevant_date&.strftime("%b %-e")
    else
      relevant_date&.strftime("%b %-e '%y")
    end
  end

  def published_timestamp
    return "" unless published
    return "" unless crossposted_at || published_at

    displayable_published_at.utc.iso8601
  end

  def displayable_published_at
    crossposted_at.presence || published_at
  end

  def series
    # name of series article is part of
    collection&.slug
  end

  def all_series
    # all series names
    user&.collections&.pluck(:slug)
  end

  def cloudinary_video_url
    return if video_thumbnail_url.blank?

    Images::Optimizer.call(video_thumbnail_url, width: 880, quality: 80)
  end

  def video_duration_in_minutes
    duration = ActiveSupport::Duration.build(video_duration_in_seconds.to_i).parts

    # add default hours and minutes for the substitutions below
    duration = duration.reverse_merge(seconds: 0, minutes: 0, hours: 0)

    minutes_and_seconds = format("%<minutes>02d:%<seconds>02d", duration)
    return minutes_and_seconds if duration[:hours] < 1

    "#{duration[:hours]}:#{minutes_and_seconds}"
  end

  def plain_html
    doc = Nokogiri::HTML.fragment(processed_html)
    doc.search(".highlight__panel").each(&:remove)
    doc.to_html
  end

  private

  def tag_keywords_for_search
    tags.pluck(:keywords_for_search).join
  end

  def calculated_path
    if organization
      "/#{organization.slug}/#{slug}"
    else
      "/#{username}/#{slug}"
    end
  end

  def set_caches
    return unless user

    self.cached_user_name = user_name
    self.cached_user_username = user_username
    self.path = calculated_path.downcase
  end

  def evaluate_markdown
    fixed_body_markdown = MarkdownProcessor::Fixer::FixAll.call(body_markdown || "")
    parsed = FrontMatterParser::Parser.new(:md).call(fixed_body_markdown)
    parsed_markdown = MarkdownProcessor::Parser.new(parsed.content, source: self, user: user)
    self.reading_time = parsed_markdown.calculate_reading_time
    self.processed_html = parsed_markdown.finalize

    if parsed.front_matter.any?
      evaluate_front_matter(parsed.front_matter)
    elsif tag_list.any?
      set_tag_list(tag_list)
    end

    self.description = processed_description if description.blank?
  rescue StandardError => e
    errors.add(:base, ErrorMessages::Clean.call(e.message))
  end

  def set_tag_list(tags)
    self.tag_list = [] # overwrite any existing tag with those from the front matter
    tag_list.add(tags, parse: true)
    self.tag_list = tag_list.map { |tag| Tag.find_preferred_alias_for(tag) }
  end

  def fetch_video_duration
    if video.present? && video_duration_in_seconds.zero?
      url = video_source_url.gsub(".m3u8", "1351620000001-200015_hls_v4.m3u8")
      duration = 0
      HTTParty.get(url).body.split("#EXTINF:").each do |chunk|
        duration += chunk.split(",")[0].to_f
      end
      self.video_duration_in_seconds = duration
      duration
    end
  rescue StandardError => e
    Rails.logger.error(e)
  end

  def before_destroy_actions
    bust_cache(destroying: true)
    article_ids = user.article_ids.dup
    if organization
      organization.touch(:last_article_at)
      article_ids.concat organization.article_ids
    end
  end

  def evaluate_front_matter(front_matter)
    self.title = front_matter["title"] if front_matter["title"].present?
    set_tag_list(front_matter["tags"]) if front_matter["tags"].present?
    self.published = front_matter["published"] if %w[true false].include?(front_matter["published"].to_s)
    self.published_at = parse_date(front_matter["date"]) if published
    self.main_image = determine_image(front_matter)
    self.canonical_url = front_matter["canonical_url"] if front_matter["canonical_url"].present?

    update_description = front_matter["description"].present? || front_matter["title"].present?
    self.description = front_matter["description"] if update_description

    self.collection_id = nil if front_matter["title"].present?
    self.collection_id = Collection.find_series(front_matter["series"], user).id if front_matter["series"].present?
  end

  def determine_image(front_matter)
    # In order to clear out the cover_image, we check for the key in the front_matter.
    # If the key exists, we use the value from it (a url or `nil`).
    # Otherwise, we fall back to the main_image on the article.
    has_cover_image = front_matter.include?("cover_image")

    if has_cover_image && (front_matter["cover_image"].present? || main_image)
      front_matter["cover_image"]
    else
      main_image
    end
  end

  def parse_date(date)
    # once published_at exist, it can not be adjusted
    published_at || date || Time.current
  end

  def validate_tag
    # remove adjusted tags
    remove_tag_adjustments_from_tag_list
    add_tag_adjustments_to_tag_list

    # check there are not too many tags
    return errors.add(:tag_list, "exceed the maximum of 4 tags") if tag_list.size > 4

    # check tags names aren't too long and don't contain non alphabet characters
    tag_list.each do |tag|
      new_tag = Tag.new(name: tag)
      new_tag.validate_name
      new_tag.errors.messages[:name].each { |message| errors.add(:tag, "\"#{tag}\" #{message}") }
    end
  end

  def remove_tag_adjustments_from_tag_list
    tags_to_remove = TagAdjustment.where(article_id: id, adjustment_type: "removal",
                                         status: "committed").pluck(:tag_name)
    tag_list.remove(tags_to_remove, parse: true) if tags_to_remove.present?
  end

  def add_tag_adjustments_to_tag_list
    tags_to_add = TagAdjustment.where(article_id: id, adjustment_type: "addition", status: "committed").pluck(:tag_name)
    return if tags_to_add.blank?

    tag_list.add(tags_to_add, parse: true)
    self.tag_list = tag_list.map { |tag| Tag.find_preferred_alias_for(tag) }
  end

  def validate_video
    if published && video_state == "PROGRESSING"
      return errors.add(:published,
                        "cannot be set to true if video is still processing")
    end

    return unless video.present? && user.created_at > 2.weeks.ago

    errors.add(:video, "cannot be added by member without permission")
  end

  def validate_collection_permission
    return unless collection && collection.user_id != user_id

    errors.add(:collection_id, "must be one you have permission to post to")
  end

  def past_or_present_date
    return unless published_at && published_at > Time.current

    errors.add(:date_time, "must be entered in DD/MM/YYYY format with current or past date")
  end

  def canonical_url_must_not_have_spaces
    return unless canonical_url.to_s.match?(/[[:space:]]/)

    errors.add(:canonical_url, "must not have spaces")
  end

  def create_slug
    if slug.blank? && title.present? && !published
      self.slug = title_to_slug + "-temp-slug-#{rand(10_000_000)}"
    elsif should_generate_final_slug?
      self.slug = title_to_slug
    end
  end

  def should_generate_final_slug?
    (title && published && slug.blank?) ||
      (title && published && slug.include?("-temp-slug-"))
  end

  def create_password
    return if password.present?

    self.password = SecureRandom.hex(60)
  end

  def update_cached_user
    self.cached_organization = organization ? Articles::CachedEntity.from_object(organization) : nil
    self.cached_user = user ? Articles::CachedEntity.from_object(user) : nil
  end

  def set_all_dates
    set_published_date
  end

  def set_published_date
    self.published_at = Time.current if published && published_at.blank?
  end

  def title_to_slug
    "#{Sterile.sluggerize(title)}-#{rand(100_000).to_s(26)}"
  end

  def touch_actor_latest_article_updated_at(destroying: false)
    return unless destroying || saved_changes.keys.intersection(%w[title cached_tag_list]).present?

    user.touch(:latest_article_updated_at)
    organization&.touch(:latest_article_updated_at)
  end

  def bust_cache(destroying: false)
    cache_bust = EdgeCache::Bust.new
    cache_bust.call(path)
    cache_bust.call("#{path}?i=i")
    cache_bust.call("#{path}?preview=#{password}")
    touch_actor_latest_article_updated_at(destroying: destroying)
  end

  def touch_collection
    collection.touch if collection && previous_changes.present?
  end

  def enrich_image_attributes
    return unless saved_change_to_attribute?(:processed_html)
  end
end
