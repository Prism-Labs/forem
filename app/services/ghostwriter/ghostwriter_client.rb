##
# GhostWriter related module
#
module Ghostwriter
  ##
  # GhostWriter API Client
  # Extends HTTParty to create a custom client
  #
  class GhostwriterClient
    include HTTParty
    base_uri "https://api.ghost-writer.io/api"

    def initialize(api_key)
      @api_key = api_key.to_s

      return unless @api_key.strip.empty?

      message = "The GhostWriter Client is not configured properly, missing API KEY!"
      raise ArgumentError, message
    end

    ##
    # Generate an article based on given keywords
    #
    # Parameters
    #  - keywords : Array of string
    #
    def generate_with_keywords(keywords, site, serp_google_tbs_qdr)
      headers = {
        "Accept" => "application/json",
        "X-MyApi-Key" => @api_key,
        "Content-Type" => "application/json"
      }
      req_body = {
        keywords: keywords,
        site: site,
        serp_google_tbs_qdr: serp_google_tbs_qdr,
        output_format: "markdown"
      }.to_json
      resp = self.class.post("/article-generator/write_by_keywords", body: req_body, headers: headers)

      raise Error, "GhostWriter API returned invalid status! #{resp.code}" unless resp.code == 200

      body = resp.to_h
      [true, body["generated_article"]]
    end
  end
end
