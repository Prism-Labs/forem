class TiktokTag < LiquidTagBase
  include ActionView::Helpers::SanitizeHelper

  PARTIAL = "liquids/tiktok".freeze
  URL_REGEXP = %r{\Ahttps://(www.)?tiktok.com/@(\w+)/video/([0-9]+)}.freeze

  def initialize(_tag_name, url, _parse_context)
    super
    @url = ActionController::Base.helpers.strip_tags(url).strip
    @oembed = parse_url
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: @oembed
    )
  end

  private

  def parse_url
    validate_url

    # Requests to Tiktok oembed API
    response = HTTParty.get("https://www.tiktok.com/oembed?url=#{@url}", format: :plain)
    # response contains: "version", "title", "html", etc
    JSON.parse response, symbolize_names: true
  end

  def validate_url
    return true if valid_url?(@url.delete(" ")) && (@url =~ URL_REGEXP)&.zero?

    raise StandardError, "Invalid Tiktok video link: #{@url}"
  end

  def valid_url?(url)
    url = URI.parse(url)
    url.is_a?(URI::HTTP)
  end
end

Liquid::Template.register_tag("tiktok", TiktokTag)
