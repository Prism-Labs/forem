require "async"
require "ld-eventsource"

##
# Zapper API related module
#
#
# Example transaction:
#
# {
#   "network": "ethereum",
#   "hash": "0x400d89391405016889d70a0717f03e33d22dcdaafe0426c3f701d556a314e74d",
#   "blockNumber": 14591765,
#   "name": "Receive",
#   "direction": "incoming",
#   "timeStamp": "1650049632",
#   "symbol": "Wrapped ApeCoin (ape.claims)",
#   "address": "0x9da458800bb0fea8e0734ecf4ba9d0e13dde7118",
#   "amount": "10.0000",
#   "from": "0x9da458800bb0fea8e0734ecf4ba9d0e13dde7118",
#   "destination": "0x5ac7983a4faafbee0150a8bf8100960887f1b102",
#   "contract": "0x9da458800bb0fea8e0734ecf4ba9d0e13dde7118",
#   "subTransactions": [
#       {
#           "type": "incoming",
#           "symbol": "Wrapped ApeCoin (ape.claims)",
#           "amount": 10,
#           "address": "0x9da458800bb0fea8e0734ecf4ba9d0e13dde7118"
#       }
#   ],
#   "nonce": "7",
#   "gasPrice": 6.2612285676e-08,
#   "gasLimit": 0.7156499100058281,
#   "input": "deprecated",
#   "gas": 0.7156499100058281,
#   "txSuccessful": true,
#   "account": "0x5ac7983a4faafbee0150a8bf8100960887f1b102",
#   "destinationEns": null,
#   "accountEns": null
# },
# {
#   "network": "ethereum",
#   "hash": "0x48122bcebed4bef466ed1ca02a315a069a749c89a1b4843fbb48836d2b71b6ae",
#   "blockNumber": 14440449,
#   "name": "Send",
#   "direction": "outgoing",
#   "timeStamp": "1648009969",
#   "symbol": "ETH",
#   "address": "0x0000000000000000000000000000000000000000",
#   "amount": "0.8480",
#   "from": "0x5ac7983a4faafbee0150a8bf8100960887f1b102",
#   "destination": "0x7f268357a8c2552623316e2562d90e642bb538e5",
#   "contract": "0x7f268357a8c2552623316e2562d90e642bb538e5",
#   "subTransactions": [
#       {
#           "type": "outgoing",
#           "symbol": "ETH",
#           "amount": 0.848,
#           "address": "0x0000000000000000000000000000000000000000"
#       }
#   ],
#   "nonce": "246",
#   "gasPrice": 4.5368317555e-08,
#   "gasLimit": 0.011566244245789257,
#   "input": "0xab834bab",
#   "gas": 0.008455157237772685,
#   "txSuccessful": true,
#   "account": "0x5ac7983a4faafbee0150a8bf8100960887f1b102",
#   "fromEns": null,
#   "accountEns": null
# },
# {
#   "network": "ethereum",
#   "hash": "0x7120d4a910ab5f41b3d864c8ec426f9e1e7b51d693462325da8295b89b8677f8",
#   "blockNumber": 14411513,
#   "name": "Exchange",
#   "direction": "exchange",
#   "timeStamp": "1647621339",
#   "symbol": "APE",
#   "address": "0x4d224452801aced8b2f0aebe155379bb5d594381",
#   "amount": "7200.0000",
#   "from": "0x5ac7983a4faafbee0150a8bf8100960887f1b102",
#   "destination": "0x68b3465833fb72a70ecdf485e0e4c7bd8665fc45",
#   "contract": "0x68b3465833fb72a70ecdf485e0e4c7bd8665fc45",
#   "subTransactions": [
#       {
#           "type": "outgoing",
#           "symbol": "APE",
#           "amount": 7200,
#           "address": "0x4d224452801aced8b2f0aebe155379bb5d594381"
#       },
#       {
#           "type": "incoming",
#           "symbol": "ETH",
#           "amount": 32.45720280351017,
#           "address": "0x0000000000000000000000000000000000000000"
#       }
#   ],
#   "nonce": "200",
#   "gasPrice": 5.5561753191e-08,
#   "gasLimit": 0.010083513654362252,
#   "input": "0x5ae401dc",
#   "gas": 0.007217916233536428,
#   "txSuccessful": true,
#   "account": "0x5ac7983a4faafbee0150a8bf8100960887f1b102",
#   "fromEns": null,
#   "accountEns": null
# },

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
      return if @zapper_fi_api_key.blank?

      api_url = "#{@base_uri}#{api_path}?api_key=#{@zapper_fi_api_key}&#{params.to_query}"
      Rails.logger.info("Calling ZAPPER FI API - #{api_url}")

      response = HTTParty.get(api_url, format: :plain)

      result = JSON.parse response

      if result.key?("statusCode") && result["statusCode"] != 200
        Rails.logger.info(result["message"])
        return
      end

      result["data"]
    end

    def call_api_get_eventstream_async(api_path, **params)
      Async do |task|
        return if @zapper_fi_api_key.blank?

        api_url = "#{@base_uri}#{api_path}?api_key=#{@zapper_fi_api_key}&#{params.to_query}"
        Rails.logger.info("Calling ZAPPER FI API (Expecting an Event-Stream) - #{api_url}")

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
            Rails.logger.info("Zapper response event stream: #{event.type}")
          end
        end

        task.sleep(20) until sse_client.closed?

        Rails.logger.info("Zapper response event stream: Closed, #{all_events.length} valid events so far")
        all_events
      end
    end

    def call_graphql(body)
      return if @zapper_fi_api_key.blank?

      Rails.logger.info("Calling Zapper GraphQL")
      Rails.logger.info(body.to_json)

      api_url = "#{@base_uri}/graphql?api_key=#{@zapper_fi_api_key}"
      response = HTTParty.post(api_url,
                               body: body.to_json,
                               headers: { "Content-Type" => "application/json" },
                               format: :plain)

      Rails.logger.info("Got response from Zapper GraphQL")
      Rails.logger.info(response)
      result = JSON.parse response

      result["data"]
    end

    # uses Zapper.fi 's GraphQL endpoint to search, find matching user, and get address from ens
    def resolve_ens(ens)
      body = {
        query: "
query search(
  $categories: [SearchResultCategory!]
  $networks: [Network!]
  $search: String!
  $maxResultsPerCategory: Float
) {
  search(
    input: {
      categories: $categories
      networks: $networks
      search: $search
      maxResultsPerCategory: $maxResultsPerCategory
    }
  ) {
    results {
      __typename
      ... on UserResult {
        ens
        address
        imageUrl
      }
    }
  }
}",
        variables: {
          categories: ["USER"],
          search: ens
        }
      }
      res = call_graphql(body)
      {
        ens: res["search"]["results"][0]["ens"],
        address: res["search"]["results"][0]["address"]
      }
    end

    # Get Historical Transactions API
    def get_transactions(address, addresses, network = nil)
      namespaced_key = "crypto_txs_#{address}__#{addresses.join('_')}__#{network}"
      Rails.cache.fetch(namespaced_key, expires_in: 900) do
        args = { address: address, addresses: addresses }
        if network.present?
          args[:network] = network
        end
        call_api_get("/v2/transactions", **args)
      end
    end

    # Get Balances API
    def get_balances(addresses)
      namespaced_key = "crypto_balances_#{addresses.join('_')}"
      Rails.cache.fetch(namespaced_key, expires_in: 900) do
        all_events = call_api_get_eventstream_async("/v2/balances", addresses: addresses).wait
        return if all_events.blank?

        totals = []
        protocol = []
        category = []
        all_events.each do |evt|
          case evt.type.to_s
          when "totals"
            totals.append(JSON.parse(evt.data))
          when "protocol"
            protocol.append(JSON.parse(evt.data))
          when "category"
            category.append(JSON.parse(evt.data))
          else
            Rails.logger.info("I found '#{evt.type}'")
          end
        end
        [totals, protocol, category]
      end
    end

    # Parse balance by type
    def get_balances_parsed(addresses)
      _totals, _protocol, category = get_balances(addresses)

      nfts = []
      wallets = []

      category.each do |b|
        b["wallet"].each do |_addr, w|
          wallets.append({
                           tokenImageUrl: w["displayProps"]["images"],
                           symbol: w["displayProps"]["label"],
                           price: w["context"]["price"],
                           balance: w["context"]["balance"],
                           balanceUSD: w["balanceUSD"],
                           network: w["network"],
                           address: w["address"]
                         })
        end
        b["nft"].each do |_addr, n|
          nfts.append({
                        collectionImg: n["displayProps"]["profileBanner"],
                        collectionName: n["displayProps"]["label"],
                        collection: {
                          imgProfile: n["displayProps"]["profileImage"],
                          floorPrice: n["context"]["floorPrice"]
                        },
                        assets: n["assets"],
                        balance: n["context"]["amountHeld"],
                        balanceUSD: n["balanceUSD"],
                        network: n["network"],
                        address: n["address"]
                      })
        end
      end

      [wallets, nfts]
    end

    # Get Gas Price API
    def get_gas_price(eip1559, network)
      call_api_get("/v1/gas-price", eip1559: eip1559, network: network)
    end

    # Get Token Prices API
    def get_prices_v3(network)
      call_api_get("/v1/prices-v3", network: network)
    end

    def get_zapper_avatar(address)
      body = {
        query: "
                query user($address: Address!) {
                  user(input: { address: $address }) {
                    address
                    avatarURI
                    level
                    xp
                    ens
                    socialStats {
                      followersCount
                      followedCount
                      followersRank
                    }
                  }
                }
            ",
        variables: {
          address: address
        }
      }
      res = call_graphql(body)
      res["user"]["avatarURI"]
    rescue StandardError
      Rails.logger.info("Failed to fetch avatar from Zapper")
    end
  end
end
