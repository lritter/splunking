# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name        = "splunking"
  s.version     = "0.0.1"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Lincoln Ritter"]
  s.email       = ["lincoln@animoto.com"]
  s.homepage    = ""
  s.summary     = %q{Splunk from Ruby}
  s.description = %q{A library for accessing the splunk search api}

  s.rubyforge_project = "splunking"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency( 'faraday' )
  s.add_dependency( 'faraday_middleware')

  s.add_dependency( 'json')
  s.add_dependency( 'hpricot')
  s.add_dependency( 'nokogiri')
end