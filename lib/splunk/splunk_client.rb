require 'net/http'
require 'faraday'
require 'nokogiri'
require 'date'
require 'set'

module Splunk
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

  class SearchResult
    attr_reader :result_data

    def initialize(result_data)
      @result_data = result_data
    end

    def time
      DateTime.parse(self['_time'])
    end

    def raw
      self['_raw']
    end

    def [](key)
      v = result_data.field("[@k=\"#{key}\"]")
      v ? v.value.text : v
    end

    def keys
      result_data.children.inject(Set.new) { |memo, node| k = node['k'] ; k ? memo.add(k) : k; memo }.to_a
    end

    def method_missing(name, *args, &blk)
      if args.empty? && blk.nil? 
        self[name.to_s]
      else
        super
      end
    end

    def respond_to?(name)
      begin
        unless self[name.to_s].nil? then true else super end
      rescue NoMethodError
        super
      end
    end
  end

  class Job
    JOBS_BASE_URL = "/services/search/jobs" unless const_defined?('JOBS_BASE_URL')
    DEFAULT_MAX_RESULTS = 50 unless const_defined?('DEFAULT_MAX_RESULTS')
    DEFAULT_OUTPUT_MODE = 'xml' unless const_defined?('DEFAULT_OUTPUT_MODE')

    attr_reader :job_id
    attr_reader :session

    def initialize(session, job_id)
      @session = session
      @job_id = job_id
    end

    def status
      response = session.get(job_path)
      Nokogiri::Slop(response.body).xpath("//s:key[@name='isDone']").text.to_i
    end

    def cancel
      response = session.post("#{job_path}/control", 'action' => 'cancel')
      puts response.inspect
    end

    def completed?
      status == 1
    end

    def wait(interval = 1)
      while !completed?
        sleep interval
      end
    end

    def results(params = {})
      # TODO: should follow the link @rel=results in the jobs status response
      # TODO: paging?
      default_params = { 'count' => DEFAULT_MAX_RESULTS }
      response = session.get("#{job_path}/results", default_params.merge(params))
      process_results(response)
      # JSON.parse(response.body)
    end

    private

    def process_results(response)
      body = response.body.strip

      if !body.empty?
        parsed_response = Nokogiri::Slop(body)
        result = parsed_response.results.result
        if result.respond_to?("length")
          # Multiple Results, build array
          result.map do |resultObj|
            SearchResult.new(resultObj)
          end
        else
          # Single results object
          [SearchResult.new(result)]
        end
      else
        []
      end
    end

    def job_path
      "#{JOBS_BASE_URL}/#{job_id}"
    end

  end

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