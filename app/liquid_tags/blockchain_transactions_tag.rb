#
# Liquid Tag to render a simple data we get from Dune Query
#
# Usage: {% blockchain_transactions network="ethereum", address="xyzxf", column=median_gas_price[, row=0][, api="zapper.fi"] %}
#        {{ blockchain_transactions_ethereum_xyzxf.0.var_name}}
#
# Example: {% blockchain_transactions network="ethereum", address="0x94c7c5f905fc888ddc48c51a90b68ddec44f8d8c", column="amount" %}
#
class BlockchainTransactionsTag < CustomLiquidTagBase

  def initialize(_tag_name, params, _parse_context)
    super
    args = __split_params(params)

    @zapper_fi_api_key = ENV.fetch("ZAPPER_FI_API_KEY", "96e0cc51-a62e-42ca-acee-910ea7d2a241")

    @api_arg = nil
    @network_arg = nil
    @row_arg = nil
    @formatter_arg = nil
    @address_arg = nil
    @column_arg = nil

    args.each do |p|
      param = __split_param_single(p)
      case param[0]
      when "api"
        @api_arg = param[1]
      when "network"
        @network_arg = param[1]
      when "address"
        @address_arg = param[1]
      when "row"
        @row_arg = param[1]
      when "column"
        @column_arg = param[1]
      when "formatter"
        @formatter_arg = param[1]
      end
    end
  end

  def call_zapper_fi_api
    if @zapper_fi_api_key.blank?
      return
    end

    api_url = "https://api.zapper.fi/v1/transactions?address=#{@address}&addresses[]=#{@address}&network=#{@network}&api_key=#{@zapper_fi_api_key}"
    puts "Calling ZAPPER FI API - #{api_url}"

    response = HTTParty.get(api_url, format: :plain)

    result = JSON.parse response

    if result.key?("statusCode") && result["statusCode"] != 200
      puts result["message"]
      return
    end

    result["data"]
  end

  def render_zapper_fi_result(context)
    if @network.blank? || @address.blank?
      puts "Missing network and address parameters"
      return
    end

    cache_key = "blockchain_transactions_zapper_fi_#{@network}_#{@address}"
    # we set the varible, which can be used, like {{dune_query_0000.0.data.median_gas_price}}
    if context.scopes.last.key?(cache_key)
      result = context.scopes.last[cache_key]
    else
      result = call_zapper_fi_api
      # cache the result
      context.scopes.last[cache_key] = result
    end

    return "" if result.blank?

    return result[@row] if @column.blank?

    case @formatter
    when "currency"
      number_to_currency(result[@row][@column])
    when "to_currency"
      number_to_currency(result[@row][@column])
    when "percentage"
      number_to_percentage(result[@row][@column])
    when "to_percentage"
      number_to_percentage(result[@row][@column])
    else
      result[@row][@column].to_s
    end
  end

  def render(context)
    @api = @api_arg.present? ? parse_value_with_context(@api_arg, context) : "zapper.fi"
    @network = @network_arg.present? ? parse_value_with_context(@network_arg, context) : "ethereum"
    @row = @row_arg.present? ? parse_value_with_context(@row_arg, context).to_i : 0
    @formatter = @formatter_arg.present? ? parse_value_with_context(@formatter_arg, context) : nil
    @address = @address_arg.present? ? parse_value_with_context(@address_arg, context) : nil
    @column = @column_arg.present? ? parse_value_with_context(@column_arg, context) : nil

    # for now, only supports zapper.fi API
    return "" unless @api == "zapper.fi"

    render_zapper_fi_result(context)
  rescue StandardError => e
    print e
  end
end

Liquid::Template.register_tag("blockchain_transactions", BlockchainTransactionsTag)
