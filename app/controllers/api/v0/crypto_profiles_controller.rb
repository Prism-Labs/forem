module Api
  module V0
    class CryptoProfilesController < ApiController
      include ActionView::Helpers::NumberHelper
      include ActionController::Live

      def transactions
        set_profile
        eth_address = @crypto_profile.ethereum_address
        result = []

        return render json: result if eth_address.blank?

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

        return render json: result if eth_address.blank?

        zapper_client = Zapper::ZapperClient.new
        @wallets, @balance_nfts = zapper_client.get_balances_parsed([eth_address])
        render json: @wallets
      rescue StandardError => e
        render json: { error: e }, status: :gone
      end

      def nfts
        set_profile
        eth_address = @crypto_profile.ethereum_address
        result = []

        return render json: result if eth_address.blank?

        zapper_client = Zapper::ZapperClient.new
        @wallets, @balance_nfts = zapper_client.get_balances_parsed([eth_address])
        render json: @balance_nfts
      rescue StandardError => e
        render json: { error: e }, status: :gone
      end

      # Return all balances as an event-stream
      def all_balances_stream
        set_profile
        eth_address = @crypto_profile.ethereum_address

        response.headers["X-Accel-Buffering"] = "no"
        response.headers['Content-Type'] = 'text/event-stream'
        response.headers['Last-Modified'] = Time.now.httpdate
        response.headers['ETag'] = '0'
        sse = SSE.new(response.stream, retry: 300, event: "message")
        if eth_address.present?
          zapper_client = Zapper::ZapperClient.new
          @wallets, @balance_nfts = zapper_client.get_balances_parsed_stream([eth_address], sse)
        end
      ensure
        sse.close
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
