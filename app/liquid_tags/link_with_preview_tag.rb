require "embedly"
require "uri"

#
# Liquid Tag to render a link with preview
#
# Usage: {% linkwithpreview "url" %}

class LinkWithPreviewTag < ScreenshotTag

  PARTIAL = "liquids/link_with_preview".freeze

  def initialize(_tag_name, url, _parse_context)
    super
    @url_arg = url.strip
  end

  def needs_static_screenshot?
    # - Looksrare.org returns invalid Thumbnail URL in OEmbed data
    LOOKSRARE_ORG_URL_REGEXP.match(@url)
  end

  def render(context)
    @url = parse_value_with_context(@url_arg, context).strip
    @url = ActionController::Base.helpers.strip_tags(@url)

    if DUNE_XYZ_URL_REGEXP.match @url
      @oembed = {
        type: "link",
        url: @url,
        html: "<div style=\"position:relative;height: 320px;\"><iframe src=\"#{@url}\" style=\"position: absolute; left: 0px; top: 0px; width: 100%; height: 100%; border-radius: 1px; pointer-events: auto; background-color: rgb(247, 246, 245);\"></iframe></div>",
      }
    else
      @oembed = parse_url

      if needs_static_screenshot?
        generate_screenshot
        puts "Generated screenshot #{@screenshot}"
        @oembed[:thumbnail_url] = @screenshot
      end
    end

    ApplicationController.render(
      partial: PARTIAL,
      locals: @oembed,
    )
  rescue StandardError => e
    print e
  end

  private

  def parse_url
    validate_url

    embedly_api = Embedly::API.new

    obj = embedly_api.oembed url: @url
    obj[0].marshal_dump
  end
end

Liquid::Template.register_tag("linkwithpreview", LinkWithPreviewTag)
