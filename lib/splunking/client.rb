require 'splunking/session'
require 'splunking/job'
require 'nokogiri'

module Splunking
  class Client
    attr_reader :session

    def self.build(username, password, host, port=8089)
      session = Session.new(username, password, host, port)
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