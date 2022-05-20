require "parse-cron"
require "securerandom"

module Everlist
  class AutopostsWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority,
                    lock: :until_and_while_executing,
                    on_conflict: :replace,
                    retry: false

    def generate_article_params_json(autopost)
      {
        tags: autopost.tags,
        description: autopost.description,
        series: autopost.series,
        body_markdown: autopost.body_markdown,
        main_image: autopost.main_image,
        autopost_id: autopost.id
      }
    end

    def persist_with_html(article)
      # Here we want to persist rendered HTML into autoposted article
      # so that the dynamic data pulled using Liquid Tag won't be changed
      # in the future.
      article.body_markdown = article.processed_html
      article.published = true

      if article.main_image.nil?
        img_url_regexp = /<img .*src="([^"]+)"/
        img_match = img_url_regexp.match(article.processed_html)
        unless img_match.nil?
          article.main_image = img_match[1]
        end
      end
      article.save
    end

    def create_article_from_autopost(autopost)
      title = "#{autopost.title} #{Time.zone.today.strftime('%m/%d/%y')}"
      article_params = generate_article_params_json(autopost)
      article_params[:title] = title
      article_params[:published] = false

      # Create an article post with live preview link
      new_article = Articles::Creator.call(@author, article_params)

      autopost.last_article_id = new_article.id
      autopost.last_article_created_at = autopost.last_article_updated_at = Time.now.utc
      autopost.save # this will render Markdown

      persist_with_html(new_article)
      new_article
    end

    def update_last_article_for_autopost(autopost)
      existing = Article.find(autopost.last_article_id)
      if existing.nil?
        autopost.last_article_id = nil
      elsif exist.published
        article_params = generate_article_params_json(autopost)
        # update article text with static previews
        existing.main_image = article_params[:main_image]
        existing.body_markdown = article_params[:body_markdown]
        existing.save # this will render Markdown

        persist_with_html(existing)
        autopost.last_article_updated_at = Time.now.utc
      end
      autopost.save
      existing
    end

    def perform
      # create an article, author will be the admin
      # Get admin user

      # Check all "approved" autoposts for their cron job setting
      Autopost.approved.each do |autopost|
        @author = autopost.user
        # check new article creation timer
        cron_parser = CronParser.new(autopost.article_create_crontab)
        prev_create = autopost.last_article_created_at.nil? ? autopost.published_at : autopost.last_article_created_at
        next_create = cron_parser.next(prev_create.localtime)
        Rails.logger.debug do
          "prev_create=#{prev_create.localtime}, next_create=#{next_create}, now=#{Time.zone.now}\n"
        end
        if next_create <= Time.zone.now
          Rails.logger.debug { "Creating a new article #{autopost.last_article_id} from autopost #{autopost.id}" }
          create_article_from_autopost(autopost)
        elsif autopost.enable_update && !autopost.last_article_id.nil?
          # article had been created already, check update article timer
          cron_parser = CronParser.new(autopost.article_update_crontab)
          prev_update = autopost.last_article_updated_at.nil? ? autopost.last_article_created_at : autopost.last_article_updated_at
          next_update = cron_parser.next(prev_update.localtime)
          Rails.logger.debug do
            "prev_update=#{prev_update.localtime}, next_create=#{next_update}, now=#{Time.zone.now}\n"
          end
          if next_update <= Time.zone.now
            Rails.logger.debug { "Updating article #{autopost.last_article_id} for autopost #{autopost.id}" }
            update_last_article_for_autopost(autopost)
          end
        end
      end
    end
  end
end
