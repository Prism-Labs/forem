require "embedly"
require "uri"

#
# Liquid Tag to render a link with preview
#
# Usage: {% linkwithpreview "url" %}

class LinkWithPreviewTag < LiquidTagBase
  include ActionView::Helpers::SanitizeHelper

  PARTIAL = "liquids/link_with_preview".freeze
  DUNE_XYZ_URL_REGEXP = %r{\Ahttps?://dune\.xyz/embeds/.*\Z}

  def initialize(_tag_name, url, _parse_context)
    super
    @url = ActionController::Base.helpers.strip_tags(url).strip

    if DUNE_XYZ_URL_REGEXP.match @url
      @oembed = {
        type: "link",
        url: @url,
        html: "<div style=\"position:relative;height: 320px;\"><iframe src=\"#{@url}\" style=\"position: absolute; left: 0px; top: 0px; width: 100%; height: 100%; border-radius: 1px; pointer-events: auto; background-color: rgb(247, 246, 245);\"></iframe></div>",
      }
    else
      @oembed = parse_url
    end
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: @oembed,
    )
  end

  private

  def parse_url
    validate_url

    embedly_api = Embedly::API.new

    obj = embedly_api.oembed url: @url
    obj[0].marshal_dump
  end

  def validate_url
    return true if valid_url?(@url.delete(" "))

    raise StandardError, "Invalid URL: #{@url}"
  end

  def valid_url?(url)
    url = URI.parse(url)
    url.is_a?(URI::HTTP)
  end
end

Liquid::Template.register_tag("linkwithpreview", LinkWithPreviewTag)
