require "async"
require "ld-eventsource"

##
# Zapper API related module
#
module Zapper
  ##
  # Zapper API Client (https://zapper.fi)
  #   Ref: Swagger Doc : https://api.zapper.fi/api/static/index.html#/
  # Extends HTTParty to create a custom client
  #
  class ZapperClient
    include HTTParty

    def initialize(api_key: nil)
      @base_uri = "https://api.zapper.fi"
      @zapper_fi_api_key = api_key.presence || ENV.fetch("ZAPPER_FI_API_KEY", "96e0cc51-a62e-42ca-acee-910ea7d2a241")

      return unless @zapper_fi_api_key.strip.empty?

      message = "The Zapper API Client is not configured properly, missing API KEY!"
      raise ArgumentError, message
    end

    def call_api_get(api_path, **params)
      if @zapper_fi_api_key.blank?
        return
      end

      api_url = "#{@base_uri}#{api_path}?api_key=#{@zapper_fi_api_key}&#{params.to_query}"
      puts "Calling ZAPPER FI API - #{api_url}"

      response = HTTParty.get(api_url, format: :plain)

      result = JSON.parse response

      if result.key?("statusCode") && result["statusCode"] != 200
        puts result["message"]
        return
      end

      result["data"]
    end

    def call_api_get_eventstream_async(api_path, **params)
      Async do |task|
        return if @zapper_fi_api_key.blank?

        api_url = "#{@base_uri}#{api_path}?api_key=#{@zapper_fi_api_key}&#{params.to_query}"
        puts "Calling ZAPPER FI API (Expecting an Event-Stream) - #{api_url}"

        all_events = []
        es_started = false
        es_ended = false

        sse_client = SSE::Client.new(api_url) do |client|
          client.on_event do |event|
            if event.type.to_s == "start"
              es_started = true
            elsif event.type.to_s == "end"
              es_ended = es_started
              if es_ended
                client.close
              end
            elsif es_started && !es_ended
              all_events.append(event)
            end
            puts("Zapper response event stream: #{event.type}")
          end
        end

        task.sleep(20) until sse_client.closed?

        puts("Zapper response event stream: Closed, #{all_events.length} valid events so far")
        all_events
      end
    end

    # Get Historical Transactions API
    def get_transactions(address, addresses, network = nil)
      namespaced_key = "crypto_txs_#{addresses.join('_')}"
      Rails.cache.fetch(namespaced_key, expires_in: 900) do
        args = { address: address, addresses: addresses }
        if network.present?
          args[:network] = network
        end
        call_api_get("/v1/transactions", **args)
      end
    end

    # Get Balances API
    def get_balances(addresses)
      all_events = call_api_get_eventstream_async("/v1/balances", addresses: addresses).wait
      return if all_events.blank?

      balances = []
      all_events.each do |evt|
        if evt.type.to_s == "balance"
          balances.append(JSON.parse(evt.data))
        else
          puts("I found '#{evt.type.to_s}'")
        end
      end

      balances
    end

    # Parse balance by type
    def get_balances_parsed(addresses)
      namespaced_key = "crypto_balances_#{addresses.join('_')}"
      Rails.cache.fetch(namespaced_key, expires_in: 900) do
        balances = get_balances(addresses)

        nfts = {}
        wallets = {}
        addresses.each do |addr|
          nfts[addr] = []
          wallets[addr] = []
        end

        balances.each do |b|
          puts("#{b['balances'].length} balance items")
          next if b["balances"].blank?

          b["balances"].each do |addr, products|
            puts("#{products['products'].length} products found at #{addr}")
            products["products"].each do |prod|
              prod["assets"].each do |asset|
                case asset["type"]
                when "nft"
                  nfts[addr].append(asset)
                when "wallet"
                  wallets[addr].append(asset)
                end
              end
            end
          end
        end

        return balances, wallets, nfts
      end
    end

    # Get Gas Price API
    def get_gas_price(eip1559, network)
      call_api_get("/v1/gas-price", eip1559: eip1559, network: network)
    end

    # Get Token Prices API
    def get_prices_v3(network)
      call_api_get("/v1/prices-v3", network: network)
    end
  end
end
