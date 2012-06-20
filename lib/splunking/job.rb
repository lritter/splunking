require 'splunking/session'
require 'splunking/search_result'
require 'nokogiri'

module Splunking
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
end