require 'faraday'

module Splunking
  class Session
    attr_reader :username
    attr_reader :password
    attr_reader :host
    attr_reader :port
    attr_reader :default_headers

    def self.create!(username, password, host, port=8089)
      instance = new(username, password, host, port)
      instance
    end

    def initialize(username, password, host, port=8089)
      @username = username
      @password = password
      @host = host
      @port = port
    end

    def get(path, params={}, headers={})
      # ensure_authenticated
      raw_get(path, params, headers)
    end

    def raw_get(path, params={}, headers={})
      http.get(path, params, headers)
    end

    def post(path, data, headers={})
      # ensure_authenticated
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
      Faraday.new(:url => "https://#{host}:#{port}", :ssl => {:verify => false}) do |builder|
        builder.use Faraday::Request::UrlEncoded  # convert request params as "www-form-urlencoded"
        builder.use Faraday::Response::Logger     # log the request to STDOUT
        builder.use Faraday::Adapter::NetHttp     # make http requests with Net::HTTP

        # builder.use FaradayMiddleware::ParseAtom,  :content_type => /\bxml$/
        # builder.use FaradayMiddleware::ParseJson, :content_type => /\bjson$/
      end.tap { |conn| conn.basic_auth(username, password) }
    end

    def ensure_authenticated
      if !authenticated?
        add_default_header('Authorization', "Splunk #{authenticate!}")
      end
    end
  end
end