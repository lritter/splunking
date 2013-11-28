# Splunking

A Splunk API client.... waaaay preliminary and experiemental...

## CLI Usage

To print raw search results as xml:

    ./bin/splunking -u <user> -p <password> --host <splunk-host> --port 8089 -s 'search "needle"' --params 'earliest_time=-15m'

## Basic gem usage

    require 'splunking'

    client = Splunking::Client.build(...)
    search_job = client.search("search string", {... extra params ...})
    search_job.wait! # block until job is completed or failed
    search_job.results

This will return xml.  I recomend using Hpricot or similar to process.
