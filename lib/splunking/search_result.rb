require 'date'
require 'nokogiri'

module Splunking
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

    def to_hash
      {}.tap do |hsh|
        result_data.children.each do |node|
          next if node.to_s.strip == ''
          hsh[node['k']] = node.value.text.strip
        end
      end
    end

   def to_json(*a)
    to_hash.to_json(*a)
   end 

  end
end