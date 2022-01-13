require "parse-cron"

module Everlist
  class AutopostsWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority,
                    lock: :until_and_while_executing,
                    on_conflict: :replace,
                    retry: false

    DUNE_XYZ_URL_REGEXP = %r{https?://dune\.xyz/embeds/[0-9]+/[0-9]+/[0-9a-zA-Z\-]+}

    def download_and_save_image(image_url)
      # download image file
      open(Rails.root.join("tmp/dune_screenshot.png"), "wb") do |file|
        IO.copy_stream(URI.open(image_url), file)
        # upload to our own file server
        ArticleImageUploader.new.tap do |uploader|
          uploader.store!(file)
          return uploader.url.starts_with?("http") ? uploader.url : URL.url(uploader.url)
        end
      end
    end

    def generate_article_params_json(autopost)
      body_markdown = autopost.body_markdown

      dune_urls = body_markdown.scan DUNE_XYZ_URL_REGEXP
      # Let's pull screenshot of the graph to be used as a main image
      # first use Embedly API to pull Oembed data
      embedly_api = Embedly::API.new

      dune_urls.each do |dune_url|
        obj = embedly_api.oembed url: dune_url
        oembed = obj[0].marshal_dump

        # This thumbnail is provided by Dune.xyz and changes over time,
        # So we want to download it and upload it to our own server and fixate it.
        screenshot = download_and_upload_image(oembed[:thumbnail_url])
        preview_url_text = "[#{dune_url}](#{dune_url})\n![#{dune_url}](#{screenshot})"

        body_markdown = body_markdown.sub(dune_url, preview_url_text)
        if main_image.nil?
          main_image = screenshot
        end
      end

      {
        tags: autopost.tags,
        description: autopost.description,
        series: autopost.series,
        body_markdown: body_markdown,
        published: true,
        main_image: main_image,
        autopost_id: autopost.id
      }
    end

    def create_article_from_autopost(autopost)
      title = "#{autopost.title} #{Time.zone.today.strftime('%m/%d/%y')}"
      article_params = generate_article_params_json(autopost)
      article_params[:title] = title

      # Create an article post with live preview link
      new_article = Articles::Creator.call(@user, article_params)

      autopost.last_article_id = new_article.id
      autopost.last_article_created_at = autopost.last_article_updated_at = Time.zone.now
      autopost.save
      new_article
    end

    def update_last_article_for_autopost(autopost)
      existing = Article.get(autopost.last_article_id)
      if existin.nil?
        autopost.last_article_id = nil
      else
        article_params = generate_article_params_json(autopost)
        # update article text with static previews
        existing.main_image = article_params[:main_image]
        existing.body_markdown = article_params[:body_markdown]
        existing.save

        autopost.last_article_updated_at = Time.zone.now
      end
      autopost.save
      existing
    end

    def perform
      # create an article, author will be the admin
      # Get admin user
      @user = Role.find_by(name: "super_admin").users.first

      # Check all "approved" autoposts for their cron job setting
      Autopost.approved.each do |autopost|
        # check new article creation timer
        cron_parser = CronParser.new(autopost.article_create_crontab)
        next_create = cron_parser.next(autopost.last_article_created_at)
        if next_create <= Time.zone.now
          print "Creating a new article #{autopost.last_article_id} from autopost #{autopost.id}"
          create_article_from_autopost(autopost)
        elsif !autopost.last_article_id.nil?
          # check update article timer
          cron_parser = CronParser.new(autopost.article_update_crontab)
          next_update = cron_parser.next(autopost.last_article_updated_at)
          if next_update <= Time.zone.now
            print "Updating article #{autopost.last_article_id} for autopost #{autopost.id}"
            update_last_article_for_autopost(autopost)
          end
        end
      end
    end
  end
end
