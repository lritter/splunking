require 'splunking/session'
require 'splunking/job'
require 'nokogiri'
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

      def initialize(options = {})
        @username = options.fetch(:username)
        @password = options.fetch(:password)
        @host     = options.fetch(:host)
        @port     = options.fetch(:port, DEFAULT_SPLUNK_SERVICE_PORT)
        @logger   = options[:logger] || Logger.new($stderr) 
      end
    end
    
    attr_reader :session

    def self.build(configuration)
      session = Session.new(configuration)
      instance = new(session)
      instance
    end

    def initialize(session)
      @session = session
    end

    def search(query)
      response = session.post(Job::JOBS_BASE_URL, 'search' => query)
      jid = Nokogiri::Slop(response.body).xpath("//sid").text
      Job.new(session, jid)
    end
  end
end