require 'faraday'
require 'splunking/job'
require 'logger'

module Splunking
  class Client
    class Configuration
      DEFAULT_SPLUNK_SERVICE_PORT = 8089 unless const_defined?('DEFAULT_SPLUNK_SERVICE_PORT')

      attr_reader :username
      attr_reader :password
      attr_reader :host
      attr_reader :port
      attr_reader :logger
      attr_reader :protocol

      def initialize(options = {})
        @username = options.fetch(:username)
        @password = options.fetch(:password)
        @host     = options.fetch(:host)
        @protocol = options.fetch(:protocol, 'https')
        @port     = options.fetch(:port, DEFAULT_SPLUNK_SERVICE_PORT)
        @logger   = options[:logger] || Logger.new($stderr) 
      end
    end
    
    attr_reader :configuration
    attr_reader :logger

    def self.build(options = {})
      new(Configuration.new(options))
    end

    def initialize(configuration)
      @configuration = configuration
      @logger = configuration.logger
    end

    def post(path, data, headers={})
      puts data.inspect
      http.post(path, data, headers)
    end

    def get(path, params={}, headers={})
      http.get(path, params, headers)
    end

    def delete(path, params={}, headers={})
      http.delete(path, params, headers)
    end

    def search(query, params={})
      Job.create(self, query, params)
    end

    private

    def http
      @http ||= Faraday.new(:url => "#{configuration.protocol}://#{configuration.host}:#{configuration.port}", :ssl => {:verify => false}) do |builder|
        builder.use Faraday::Request::UrlEncoded            # convert request params as "www-form-urlencoded"
        builder.use Faraday::Response::Logger, configuration.logger  # Log request/response info
        builder.use Faraday::Adapter::NetHttp               # make http requests with Net::HTTP

        # builder.use FaradayMiddleware::ParseAtom,  :content_type => /\bxml$/
        # builder.use FaradayMiddleware::ParseJson, :content_type => /\bjson$/
      end.tap { |conn| conn.basic_auth(configuration.username, configuration.password) }
    end

  end
end