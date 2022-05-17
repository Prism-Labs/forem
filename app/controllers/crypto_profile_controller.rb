class CryptoProfileController < ApplicationController
  before_action :authenticate_user!, except: %i[index]
  before_action :set_cache_control_headers, only: %i[index]

  rescue_from ArgumentError, with: :bad_request

  def index
    # Not supported
    if params[:slug].present?
      params[:ethereum_address] = normalize_ethereum_address(params[:slug])
      params[:ens] = normalize_ens_address(params[:slug])
      params[:web3_username] = normalize_web3_address(params[:slug])
    end

    # puts "\n\n\n\n\n"
    # puts "Slug: #{params[:slug]}"
    # puts "Ethereum: #{params[:ethereum_address]}"
    # puts "ENS: #{params[:ens]}"
    # puts "Web3:#{params[:web3_username]}"
    # puts "\n\n\n\n\n"

    @crypto_profile = CryptoProfile.find_by(ethereum_address: params[:ethereum_address]) if params[:ethereum_address].present?
    @crypto_profile ||= CryptoProfile.find_by(ens: params[:ens]) if params[:ens].present?
    @crypto_profile ||= CryptoProfile.find_by(web3_username: params[:web3_username]) if params[:web3_username].present?
    @crypto_profile ||= CryptoProfile.find_by(twitter_username: params[:slug].tr("@", "")) if params[:slug].present?
    @crypto_profile ||= CryptoProfile.find_by(github_username: params[:slug].tr("@", "")) if params[:slug].present?

    if @crypto_profile.nil?
      handle_no_profile_on_system
    end

    @transactions = nil
    @balance_nfts = nil
    @balances = nil
    @wallets = nil
    handle_user_index
  end

  def ethereum_index
    if params[:ethereum].present?
      params[:ethereum_address] = normalize_ethereum_address(params[:ethereum])
      params[:ens] = normalize_ens_address(params[:slug])
    end

    @crypto_profile = CryptoProfile.find_by(ethereum_address: params[:ethereum_address]) if params[:ethereum_address].present?
    @crypto_profile ||= CryptoProfile.find_by(ens: params[:ens]) if params[:ens].present?

    handle_user_index
  end

  def twitter_index
    @crypto_profile = CryptoProfile.find_by(twitter_username: params[:twitter_username].tr("@", "")) if params[:twitter_username].present?

    handle_user_index
  end

  def github_index
    @crypto_profile = CryptoProfile.find_by(github_username: params[:github_username].tr("@", "")) if params[:github_username].present?

    handle_user_index
  end

  private

  def handle_no_profile_on_system
    # if the profile is not yet found in the system, and the address is a valid
    # ethereum or ENS address, we will enquire Zapper.fi API to see if there is an account
    # with the address. If we find one, then we will create a new profile for the addres in our system.
    eth_address = params[:ethereum_address] || params[:ens]
    return if eth_address.blank? || eth_address.strip.empty?

    begin
      @crypto_profile = CryptoProfile.new(ethereum_address: params[:ethereum_address],
                                          ens: params[:ens], web3_username: params[:web3_username])
      @crypto_profile.save
      puts "Created a new crypto profile from user visited page"
    rescue StandardError => e
      print(e)
    end
  end

  def set_profile_title
    @crypto_profile_title = @crypto_profile.name || params[:ens] || params[:ethereum_address] || params[:web3_username]
  end

  def set_profile_avatar
    if @crypto_profile.ethereum_address.present?
      zapper_client = Zapper::ZapperClient.new
      @crypto_profile.profile_image_url = zapper_client.get_zapper_avatar(@crypto_profile.ethereum_address)
    end
  end

  # Render Crypto profile page based on given @crypto_profile
  def handle_user_index
    not_found unless @crypto_profile

    if @crypto_profile.user.present?
      # if the profile is linked to the NewSignal user
      # redirect to the user profile page
      return redirect_to user_profile_path(@crypto_profile.user.username.downcase)
    end

    params[:state] ||= "transactions"

    # Otherwise show the profile
    set_profile_title
    set_profile_avatar
    set_profile_json_ld

    # set_crypto_account_balance

    render template: "users/crypto_profile_show"
  end

  def normalize_ethereum_address(str, default = nil)
    str = str.downcase
    return "0x#{str}" if str.length == 40 && !str.starts_with?("0x")

    return str if str.length == 42 && str.starts_with?("0x")

    default
  end

  def normalize_ens_address(str, default = nil)
    str = str.downcase

    return str if str.ends_with?(".eth")

    return str.replace(".xyz", "") if str.ends_with?(".eth.xyz")

    default
  end

  def normalize_web3_address(str, default = nil)
    str = str.downcase

    return str.replace(".eth.xyz", "") if str.ends_with?(".eth.xyz")

    default
  end

  def set_crypto_account_balance
    # Let's the the Crypto account details for the user if he has one
    # if the user has the ethereum address set.
    zapper_client = Zapper::ZapperClient.new

    if @crypto_profile.ethereum_address.blank? && @crypto_profile.ens.present?
      begin
        resolved = zapper_client.resolve_ens(@crypto_profile.ens)
        @crypto_profile.ethereum_address = resolved[:address]
        @crypto_profile.save
      rescue StandardError => e
        print(e)
      end
    end

    eth_address = @crypto_profile.ethereum_address
    if eth_address.blank? || eth_address.strip.empty?
      @balances = @balance_nfts == @transactions = []
    else
      begin
        @wallets, @balance_nfts = zapper_client.get_balances_parsed([eth_address])
        @wallets = @wallets
        @balance_nfts = @balance_nfts
        @transactions ||= params[:state] == "transactions" ? zapper_client.get_transactions(eth_address, []) : []
      rescue StandardError => e
        print(e)
      end
    end
  end

  def set_profile_json_ld
    # For more info on structuring data with JSON-LD,
    # please refer to this link: https://moz.com/blog/json-ld-for-beginners
    @crypto_profile_json_ld = {
      "@context": "http://schema.org",
      "@type": "Person",
      mainEntityOfPage: {
        "@type": "WebPage",
        "@id": URL.crypto_profile(@crypto_profile),
      },
      url: URL.crypto_profile(@crypto_profile),
      sameAs: profile_same_as,
      image: Images::Profile.call(@crypto_profile.profile_image_url, length: 320),
      name: @crypto_profile.name,
      email: @crypto_profile.email,
      description: @crypto_profile.description
    }.reject { |_, v| v.blank? }
  end

  def profile_same_as
    # For further information on the sameAs property, please refer to this link:
    # https://schema.org/sameAs
    [
      @crypto_profile.twitter_username.present? ? "https://twitter.com/#{@crypto_profile.twitter_username}" : nil,
      @crypto_profile.github_username.present? ? "https://github.com/#{@crypto_profile.github_username}" : nil,
      @crypto_profile.website_url,
    ].reject(&:blank?)
  end
end
