module Api
  module V0
    class CryptoProfilesController < ApiController
      include ActionView::Helpers::NumberHelper

      before_action :authenticate!

      def transactions
        set_profile
        eth_address = @crypto_profile.ethereum_address
        result = []
        zapper_client = Zapper::ZapperClient.new
        @transactions = zapper_client.get_transactions(eth_address, [])
        @transactions.each do |tx|
          result.append({
                          txSuccessful: tx["txSuccessful"],
                          direction: tx["direction"],
                          hash: tx["hash"],
                          destination: tx["destination"],
                          from: tx["from"],
                          timeStamp: Time.at(tx["timeStamp"].to_i),
                          amount: number_with_precision(tx["amount"], precision: 4, significant: true, strip_insignificant_zeros: true),
                          gas: number_with_precision(tx["gas"], precision: 4, significant: true, strip_insignificant_zeros: true)
                        })
        end
        render json: result
      rescue StandardError => e
        render json: { error: e }, status: 410
      end

      def balances
        set_profile
        eth_address = @crypto_profile.ethereum_address
        result = []
        zapper_client = Zapper::ZapperClient.new
        _all_balances, @wallets, @balance_nfts = zapper_client.get_balances_parsed([eth_address])
        @wallets = @wallets[eth_address]
        @wallets.each do |wallet|
          wallet["tokens"].each do |token|
            result.append({
                            tokenImageUrl: token["tokenImageUrl"],
                            symbol: token["symbol"],
                            price: number_to_currency(token["price"].to_f),
                            balance: number_with_precision(token["balance"], precision: 4, significant: true, strip_insignificant_zeros: true),
                            balanceUSD: number_to_currency(token["balanceUSD"].to_f)
                          })
          end
        end
        render json: result
      rescue StandardError => e
        render json: { error: e }, status: 410
      end

      def nfts
        set_profile
        eth_address = @crypto_profile.ethereum_address
        result = []
        zapper_client = Zapper::ZapperClient.new
        _all_balances, @wallets, @balance_nfts = zapper_client.get_balances_parsed([eth_address])
        @balance_nfts = @balance_nfts[eth_address]
        @balance_nfts.each do |asset|
          asset["tokens"].each do |token|
            next if !token["shouldDisplay"]

            result.append({
                            collectionImg: token["collectionImg"],
                            collectionName: token["collectionName"],
                            collection: {
                              imgProfile: token["collection"]["imgProfile"],
                              floorPrice: number_with_precision(token["collection"]["floorPrice"].to_f, precision: 5, significant: true, strip_insignificant_zeros: true)
                            },
                            balance: number_with_precision(token["balance"], precision: 0, significant: true, strip_insignificant_zeros: true),
                            balanceUSD: number_to_currency(token["balanceUSD"].to_f)
                          })
          end
        end
        render json: result
      rescue StandardError => e
        render json: { error: e }, status: 410
      end

      private

      def set_profile
        @crypto_profile = CryptoProfile.find_by(id: params[:id]) if params[:id].present?

        return not_found unless @crypto_profile

        resolve_ens
      end

      def resolve_ens
        return unless @crypto_profile.ethereum_address.blank? && @crypto_profile.ens.present?

        zapper_client = Zapper::ZapperClient.new
        resolved = zapper_client.resolve_ens(@crypto_profile.ens)
        @crypto_profile.ethereum_address = resolved[:address]
        @crypto_profile.save
      rescue StandardError => e
        print(e)
      end
    end
  end
end
