Gem::Specification.new do |s|
  s.name = "playlyfe"
  s.version     = '0.3.0'
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.rubygems_version = %q{1.6.2}
  s.license     = 'ApacheV2'
  s.summary     = "The playlyfe ruby sdk"
  s.description = "This gem can be used to interact with the playlyfe gamification platform using oauth 2.0"
  s.author     = 'Peter John'
  s.email       = 'peter@playlyfe.com'
  s.files       = ["Rakefile", "lib/playlyfe.rb"]
  s.test_files = ["test/test.rb"]
  s.homepage    = 'https://github.com/pyros2097/playlyfe-ruby-sdk'
  s.require_paths = ["lib"]
  s.add_runtime_dependency 'faraday', '0.8'
  s.add_runtime_dependency 'jwt', '1.0'
  s.add_runtime_dependency 'json', '1.8.1'
end

