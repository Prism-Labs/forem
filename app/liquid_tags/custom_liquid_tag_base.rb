require "uri"

#
# Base class to be used to define Custom Liquid Tags
#

class CustomLiquidTagBase < LiquidTagBase
  include ActionView::Helpers::SanitizeHelper
  include ActionView::Helpers::NumberHelper

  protected

  def validate_url
    raise StandardError, "Empty URL" if @url.blank?

    return true if valid_url?(@url.delete(" "))

    raise StandardError, "Invalid URL: #{@url}"
  end

  def valid_url?(url)
    url = URI.parse(url)
    url.is_a?(URI::HTTP)
  end

  def __split_params(params)
    params.split(",").map(&:strip)
  end

  def __split_param_single(param)
    param.split("=").map(&:strip)
  end

  def parse_value_with_context(str, context)
    if str.start_with?('"') && str.end_with?('"')
      str.delete_prefix('"').delete_suffix('"')
    elsif str.start_with?("'") && str.end_with?("'")
      str.delete_prefix("'").delete_suffix("'")
    elsif context.present?
      v = context.find_variable(str)

      return v if v.present?

      str
    else
      str
    end
  rescue StandardError
    str
  end
end
