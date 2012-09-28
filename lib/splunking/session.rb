require 'faraday'

module Splunking
  class Session
    attr_reader :configuration
    attr_reader :default_headers

    def initialize(configuration)
      @configuration = configuration
    end

    def get(path, params={}, headers={})
      raw_get(path, params, headers)
    end

    def raw_get(path, params={}, headers={})
      http.get(path, params, headers)
    end

    def post(path, data, headers={})
      raw_post(path, data, headers)
    end

    def raw_post(path, data, headers={})
      http.post(path, data, headers)
    end

    def default_headers
      @default_headers ||= {}
      @default_headers
    end

    def add_default_header(key, value)
      default_headers[key] = value
      default_headers
    end

    private

    def http
      @http ||= Faraday.new(:url => "https://#{configuration.host}:#{configuration.port}", :ssl => {:verify => false}) do |builder|
        builder.use Faraday::Request::UrlEncoded            # convert request params as "www-form-urlencoded"
        builder.use Faraday::Response::Logger, configuration.logger  # Log request/response info
        builder.use Faraday::Adapter::NetHttp               # make http requests with Net::HTTP

        # builder.use FaradayMiddleware::ParseAtom,  :content_type => /\bxml$/
        # builder.use FaradayMiddleware::ParseJson, :content_type => /\bjson$/
      end.tap { |conn| conn.basic_auth(configuration.username, configuration.password) }
    end
  end
end