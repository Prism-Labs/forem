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
    return true if LOOKSRARE_ORG_URL_REGEXP.match(@url)

    false
  end

  def render(context)
    @url = parse_value_with_context(@url_arg, context).strip
    url = URI.extract(@url, /http(s)?/)
    @url = url.last unless url.empty?
    Rails.logger.debug { "final url: #{@url}" }

    if exclude_from_embedly?
      @oembed = {
        title: nil,
        description: nil,
        type: "link",
        url: @url,
        html: "<div style=\"position:relative;height: 320px;\"><iframe src=\"#{@url}\" style=\"position: absolute; left: 0px; top: 0px; width: 100%; height: 100%; border-radius: 1px; pointer-events: auto; background-color: rgb(247, 246, 245);\"></iframe></div>"
      }
    else
      @oembed = get_oembed_embely(@url)
    end

    if needs_static_screenshot?
      generate_screenshot
      Rails.logger.debug { "Generated screenshot #{@screenshot}" }
      @oembed[:thumbnail_url] = @screenshot
      @oembed.delete(:html)
    end

    ApplicationController.render(
      partial: PARTIAL,
      locals: @oembed,
    )
  rescue StandardError => e
    Rails.logger.error("#{e}\n#{e.backtrace}")
  end
end

Liquid::Template.register_tag("linkwithpreview", LinkWithPreviewTag)
