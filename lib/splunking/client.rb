require 'splunking/session'
require 'splunking/job'
require 'nokogiri'
require 'logger'

module Splunking
  class Client
    DEFAULT_SPLUNK_SERVICE_PORT = 8089 unless const_defined?('DEFAULT_SPLUNK_SERVICE_PORT')
    attr_reader :session

    def self.build(options={})
      default_options = {
        :port   => DEFAULT_SPLUNK_SERVICE_PORT,
        :logger => Logger.new($stderr)
      }

      o = default_options.merge(options)
      session = Session.new(o[:username], o[:password], o[:host], o[:port], o[:logger])
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