require 'splunking/search_result'
require 'hpricot'

module Splunking
  class Job
    JOBS_BASE_URL = "/services/search/jobs" unless const_defined?('JOBS_BASE_URL')
    DEFAULT_MAX_RESULTS = 50 unless const_defined?('DEFAULT_MAX_RESULTS')
    DEFAULT_OUTPUT_MODE = 'xml' unless const_defined?('DEFAULT_OUTPUT_MODE')
    FAILED_STATUS = 'FAILED' unless const_defined?('FAILED_STATUS')
    DONE_STATUS = 'DONE' unless const_defined?('DONE')

    attr_reader :job_id
    attr_reader :client
    attr_reader :params
    attr_reader :last_status_response
    attr_reader :last_results_response

    def self.create(client, query, params={})
      build_from_job_response(client, client.post(JOBS_BASE_URL, {'search' => query}.merge(params)).body)
    end

    def self.build_from_job_response(client, response)
      job_id = (Hpricot(response)/"/response/sid").inner_html
      new(client, job_id)
    end

    def initialize(client, job_id)
      @client = client
      @job_id = job_id
    end

    def status
      @last_status_response = Hpricot(client.get(job_path).body)
      (last_status_response/("entry/content//[@name='dispatchState']")).first.inner_html
    end

    def cancel
      client.delete(job_path).body
    end

    def completed?
      is_completed?(status)
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
      response = client.get("#{job_path}/results", default_params.merge(params))
      response.body
    end

    private

    def is_completed?(s)
      s == DONE_STATUS
    end

    def is_failed?(s)
      s == FAILED_STATUS
    end

    def job_path
      "#{JOBS_BASE_URL}/#{job_id}"
    end

  end
end