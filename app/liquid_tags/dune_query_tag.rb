#
# Liquid Tag to render a simple data we get from Dune Query
#
# Usage: {% dune_query "7180", column=median_gas_price, row=0 %}
#        {{dune_query_7180.0.var_name}}
#
class DuneQueryTag < LiquidTagBase
  include ActionView::Helpers::SanitizeHelper
  include ActionView::Helpers::NumberHelper

  def initialize(_tag_name, params, _parse_context)
    super
    args = __split_params(params)

    @dune_query_id = __strip_quote(args[0])
    @column = __strip_quote(args[1])
    @row = 0
    @formatter = nil

    args.each do |p|
      param = __split_param_single(p)
      case param[0]
      when "row"
        @row = __strip_quote(param[1]).to_i
      when "column"
        @column = __strip_quote(param[1])
      when "formatter"
        @formatter = __strip_quote(param[1])
      end
    end
  end

  def get_dune_query_result
    dune_url = "https://dune.xyz/queries/#{@dune_query_id}"
    puts "DUNE Query : #{dune_url}"

    script = "#{__dir__}/../../everlist/duneanalytics/client.py"
    output = %x(python #{script} --username #{ENV["DUNE_USERNAME"]} --password #{ENV["DUNE_PASSWORD"]} #{dune_url})
    result = JSON.parse(output)

    if result.key?(:error)
      print result
      return
    end

    result["data"]["get_result_by_result_id"]
  end

  def render(context)
    # we set the varible, which can be used, like {{dune_query_0000.0.data.median_gas_price}}
    cache_key = "dune_query_#{@dune_query_id}"
    if context.scopes.last[cache_key].nil?
      result = get_dune_query_result
      # cache the result
      context.scopes.last[cache_key] = result
    else
      result = context.scopes.last[cache_key]
    end

    case @formatter
    when "currency"
      number_to_currency(result[@row]["data"][@column])
    when "to_currency"
      number_to_currency(result[@row]["data"][@column])
    when "percentage"
      number_to_percentage(result[@row]["data"][@column])
    when "to_percentage"
      number_to_percentage(result[@row]["data"][@column])
    else
      result[@row]["data"][@column].to_s
    end
  end

  private

  def __split_params(params)
    params.split(",").map(&:strip)
  end

  def __split_param_single(param)
    param.split("=").map(&:strip)
  end

  def __strip_quote(str)
    if str.start_with?('"') && str.end_with?('"')
      str.delete_prefix('"').delete_suffix('"')
    elsif str.start_with?("'") && str.end_with?("'")
      str.delete_prefix("'").delete_suffix("'")
    else
      str
    end
  end
end

Liquid::Template.register_tag("dune_query", DuneQueryTag)
