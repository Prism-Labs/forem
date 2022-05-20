module Everlist
  class DuneAutopostWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority,
                    lock: :until_and_while_executing,
                    on_conflict: :replace,
                    retry: false

    def helper
      @helper ||= Class.new do
        include ActionView::Helpers::NumberHelper
      end.new
    end

    def _get_recent_gas_prices
      # Gas Cost for Typical Actions at Recent Gas Prices
      #
      # return format (gas price is in Gwei, all "costs" are in USD):
      # {
      #  "cost_of_compound_erc20_deposit": 74.06160421811867,
      #  "cost_of_erc20_approval": 17.35688622325879,
      #  "cost_of_erc20_transfer": 16.124710861045845,
      #  "cost_of_eth_transfer": 8.217111021426453,
      #  "cost_of_uniswap_trade": 49.65443673847598,
      #  "median_gas_price": 104.120754386,
      #  "median_gas_price_yesterday": 56.587030742,
      #  "median_gas_price_today": 71.881896559,
      # }
      #
      dune_url = "https://dune.xyz/queries/294162"
      python_scripts_root = "#{__dir__}/../../everlist/python/";
      output = `cd #{python_scripts_root} && pyenv exec python duneanalytics.py --username #{ENV["DUNE_USERNAME"]} --password #{ENV["DUNE_PASSWORD"]} #{dune_url}`
      result = JSON.parse(output)

      if result.key?(:error)
        return
      end

      result["data"]["get_result_by_result_id"][0]["data"]
    end

    def _download_and_upload_image(image_url)
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

    def generate_article_params_json(use_dynamic_preview)
      dune_url = "https://dune.xyz/embeds/4298/8356/3db4e10d-24f1-41db-b88e-8cf40ec4cefc"
      dune_url2 = "https://dune.xyz/embeds/7872/15688/976a8f77-d949-45f3-97ce-9881987b8ff8"

      prices = _get_recent_gas_prices
      if !prices.nil? && prices["median_gas_price_yesterday"].positive?
        gas_price_change = (prices["median_gas_price_today"] - prices["median_gas_price_yesterday"]) / prices["median_gas_price_yesterday"] * 100.0
        gas_price_change_text = "Gas prices changed [[#{helper.number_to_percentage(gas_price_change,
                                                                                    precision: 1)}]] since yesterday."
      else
        gas_price_change_text = ""
      end

      gas_prices_text = "Gas prices for the past 24hrs
Eth Transfer: #{helper.number_to_currency(prices['cost_of_eth_transfer'])}
ERC20 Transfer: #{helper.number_to_currency(prices['cost_of_erc20_transfer'])}
ERC20 Approval: #{helper.number_to_currency(prices['cost_of_erc20_approval'])}
Uniswap trade: #{helper.number_to_currency(prices['cost_of_uniswap_trade'])}
Compound Deposit: #{helper.number_to_currency(prices['cost_of_compound_erc20_deposit'])}"

      # Let's pull screenshot of the graph to be used as a main image
      # first use Embedly API to pull Oembed data
      embedly_api = Embedly::API.new

      obj = embedly_api.oembed url: dune_url
      oembed = obj[0].marshal_dump

      if use_dynamic_preview
        preview_url_text = "{% linkwithpreview #{dune_url} %}"
        preview_url_text2 = "{% linkwithpreview #{dune_url2} %}"

        # This thumbnail is provided by Dune.xyz and changes over time
        main_image = oembed[:thumbnail_url]
      else
        obj2 = embedly_api.oembed url: dune_url2
        oembed2 = obj2[0].marshal_dump

        # This thumbnail is provided by Dune.xyz and changes over time,
        # So we want to download it and upload it to our own server and fixate it.
        screenshot = _download_and_upload_image(oembed[:thumbnail_url])
        screenshot2 = _download_and_upload_image(oembed2[:thumbnail_url])

        preview_url_text = "[#{dune_url}](#{dune_url})\n![#{dune_url}](#{screenshot})"
        preview_url_text2 = "[#{dune_url2}](#{dune_url2})\n![#{dune_url2}](#{screenshot2})"

        main_image = screenshot
      end

      {
        tags: %w[gas ethereum],
        description: "",
        series: "Gas prices",
        body_markdown: "#{gas_price_change_text}\n#{preview_url_text}\n\n#{gas_prices_text}\n\n#{preview_url_text2}",
        published: true,
        main_image: main_image
      }
    end

    def perform(update_to_static)
      # create an article, author will be the admin

      # Get admin user
      @user = Role.find_by(name: "super_admin").users.first

      title = "Gas price report #{Time.zone.today.strftime('%m/%d/%y')}"

      existing = Article.find_by(title: title)
      if existing.nil?
        article_params = generate_article_params_json(true)
        article_params[:title] = title

        # Create an article post with live preview link
        Articles::Creator.call(@user, article_params)
      else
        article_params = generate_article_params_json(!update_to_static)
        # update article text with static previews
        existing.main_image = article_params[:main_image]
        existing.body_markdown = article_params[:body_markdown]

        existing.save
      end
    end
  end
end
