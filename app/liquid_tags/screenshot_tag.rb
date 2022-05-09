require "embedly"
require "uri"

#
# Liquid Tag to render screenshot of a link
#
# Usage: {% screenshot "url" %}

class ScreenshotTag < CustomLiquidTagBase

  DUNE_XYZ_URL_REGEXP = %r{\Ahttps?://dune\.xyz/embeds/.*\Z}
  LOOKSRARE_ORG_URL_REGEXP = %r{\Ahttps?://looksrare\.org/.*\Z}

  def initialize(_tag_name, url, _parse_context)
    super
    @url_arg = url.strip
  end

  def download_and_save_image(image_url)
    temp_file = Rails.root.join("tmp/screenshot_#{SecureRandom.hex}.png")
    # download image file
    File.open(temp_file, "wb") do |file|
      IO.copy_stream(URI.open(image_url), file)
      # upload to our own file server
      ArticleImageUploader.new.tap do |uploader|
        uploader.store!(file)
        return uploader.url.starts_with?("http") ? uploader.url : URL.url(uploader.url)
      end
    ensure
      File.delete(file) # delete the temp file once done
    end
  end

  def exclude_from_embedly?
    # - Dune XYZ 's own screenshot API seems to be dead now
    # - Looksrare.org returns invalid Thumbnail URL in OEmbed data
    DUNE_XYZ_URL_REGEXP.match(@url) || LOOKSRARE_ORG_URL_REGEXP.match(@url)
  end

  def generate_screenshot
    puts "Generating screenshot of #{@url}"
    thumbnail_urls = []

    begin
      unless exclude_from_embedly?
        embedly_api = Embedly::API.new
        obj = embedly_api.oembed url: @url
        oembed = obj[0].marshal_dump
        thumbnail_urls.append(oembed[:thumbnail_url])
      end
    rescue StandardError
      # do nothing
    end

    # TODO: consider moving the following thum.io settings to .env values
    thum_io_key_id = "54756"
    thum_io_key_value = "2434ae0edc63c7d7fa237e158995ae18"
    thumbnail_urls.append("https://image.thum.io/get/auth/#{thum_io_key_id}-#{thum_io_key_value}/#{@url}")

    thumbnail_counter = 0
    # This thumbnail is provided by Dune.xyz and changes over time,
    # So we want to download it and upload it to our own server and fixate it.
    begin
      thumbnail_counter += 1
      @screenshot = download_and_save_image(thumbnail_urls[thumbnail_counter - 1])
    rescue StandardError
      retry if thumbnail_counter < thumbnail_urls.length
      # Failed to download image?
      @screenshot = nil
    end
    @screenshot
  end

  def render(context)
    @url = parse_value_with_context(@url_arg, context).strip
    @url = URI.extract(@url, /http(s)?/)

    generate_screenshot

    return %("<a href="#{@url}">#{@url}</a>") if @screenshot.nil?

    %(<a href="#{@url}"><img src="#{@screenshot}" /></a>)
  rescue StandardError => e
    print e
  end
end

Liquid::Template.register_tag("screenshot", ScreenshotTag)
