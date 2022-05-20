Embedly.configure do |config|
  # prints debug messages to the logger
  config.debug = !ENV["EMBEDLY_VERBOSE"].nil?

  # use a custom logger
  # config.logger = MyAwesomeLogger.new(STDERR)

  # Choose a request adatper (net_http, typhoeus or faraday)
  # config.request_with :faraday

  config.key = ENV["EMBEDLY_KEY"]
end
