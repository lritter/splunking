# Splunking

A Splunk API client.... waaaay preliminary and experiemental...

# Basic idea

    require 'lib/splunk/splunk_client'

    c = Splunk::Client.build('user', 'pass', 'splunk.foo.com')
    j = c.search('savedsearch my_saved_search').tap { |job| job.wait }
    j.results