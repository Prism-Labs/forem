module Api
  module V0
    class CryptoProfilesController < ApiController
      include ActionView::Helpers::NumberHelper

      def transactions
        set_profile
        eth_address = @crypto_profile.ethereum_address
        result = []
        zapper_client = Zapper::ZapperClient.new
        @transactions = zapper_client.get_transactions(eth_address, [])
        render json: @transactions
      rescue StandardError => e
        render json: { error: e }, status: :gone
      end

      def balances
        set_profile
        eth_address = @crypto_profile.ethereum_address
        result = []
        zapper_client = Zapper::ZapperClient.new
        @wallets, @balance_nfts = zapper_client.get_balances_parsed([eth_address])
        @wallets.each do |wallet|
          result.append({
                          tokenImageUrl: wallet[:tokenImageUrl][0],
                          symbol: wallet[:symbol],
                          price: number_to_currency(wallet[:price].to_f, precision: 4, significant: true,
                                                                         strip_insignificant_zeros: true),
                          balance: number_with_precision(wallet[:balance], precision: 4, significant: true,
                                                                           strip_insignificant_zeros: true),
                          balanceUSD: number_to_currency(wallet[:balanceUSD].to_f, precision: 4, significant: true,
                                                                                   strip_insignificant_zeros: true)
                        })
        end
        render json: result
      rescue StandardError => e
        render json: { error: e }, status: :gone
      end

      def nfts
        set_profile
        eth_address = @crypto_profile.ethereum_address
        result = []
        zapper_client = Zapper::ZapperClient.new
        @wallets, @balance_nfts = zapper_client.get_balances_parsed([eth_address])
        @balance_nfts.each do |asset|
          result.append({
                          collectionImg: asset[:collectionImg],
                          collectionName: asset[:collectionName],
                          collection: {
                            imgProfile: asset[:collection][:imgProfile],
                            floorPrice: number_with_precision(asset[:collection][:floorPrice].to_f, precision: 5,
                                                                                                    significant: true,
                                                                                                    strip_insignificant_zeros: true)
                          },
                          balance: number_with_precision(asset[:balance], precision: 0,
                                                                          significant: true,
                                                                          strip_insignificant_zeros: true),
                          balanceUSD: number_to_currency(asset[:balanceUSD].to_f)
                        })
        end
        render json: result
      rescue StandardError => e
        render json: { error: e }, status: :gone
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
        Rails.logger.debug(e)
      end
    end
  end
end
