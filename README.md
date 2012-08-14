# Splunking

A Splunk API client.... waaaay preliminary and experiemental...

# Basic idea

    require 'lib/splunking/client'

    c = Splunking::Client.build(:username => 'user', :password => 'pass', :host => 'splunk.foo.com')
    j = c.search('savedsearch my_saved_search').tap { |job| job.wait }
    j.results