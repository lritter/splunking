require 'optparse'
require 'splunking/client'
require 'logger'
require 'json'
require 'pp'

module Splunking
  class CLI
    attr_reader :argv
    attr_reader :options

    def initialize(argv)
      @argv = argv
    end

    def parse_args
      @options = {}
      option_parser.parse!(argv)
      options[:port] ||= ::Splunking::Client::DEFAULT_SPLUNK_SERVICE_PORT
      options[:logger] ||= Logger.new($stderr)
      options[:log_level] ||= Logger::ERROR
      options[:logger].level = options[:log_level]
    end

    def validate_options
      mandatory = [:username, :password, :host, :search]
      missing_args = mandatory.inject([]) do |missing, item| 
        missing << item if !options.key?(item)
        missing
      end

      if !missing_args.empty?
        raise OptionParser::MissingArgument, missing_args.join(', ')
      end
    end

    def run
      parse_args
      validate_options
      puts JSON.pretty_generate(options)
      results = search
      puts format_results(results)#.map(&:to_hash)
    rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
      $stderr.puts e.message
      $stderr.puts option_parser
      exit 1
    end

    def format_results(results)
      JSON.pretty_generate(results)
    end

    private
    def client
      ::Splunking::Client.build(options)
    end

    def search
      job = client.search(options[:search])
      job.wait
      job.results
    end

    def option_parser
      @option_parser ||= OptionParser.new do |opts|
        opts.banner = "Usage: example.rb [options]"

        opts.on("-u", "--username USER") do |u|
          options[:username] = u
        end

        opts.on("-p", "--password PASS") do |p|
          options[:password] = p
        end

        opts.on("--host HOST") do |h|
          options[:host] = h
        end

        opts.on("--port [PORT]", OptionParser::DecimalInteger) do |port|
          options[:port] = port
        end

        opts.on("--log-level [LEVEL]") do |level|
          options[:log_level] = Logger.const_get(level.upcase)
        end

        opts.on("-s", "--search SEARCH", "Search as you would type it into splunk") do |s|
          options[:search] = s
        end
      end
    end

  end
end
