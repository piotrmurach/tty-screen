source "https://rubygems.org"

gemspec

if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("2.5.0")
  gem "coveralls_reborn", "~> 0.22.0"
  gem "simplecov", "~> 0.21.0"
end
gem "json", "2.4.1" if RUBY_VERSION == "2.0.0"
gem "yardstick", "~> 0.9.9"

if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("2.1.0")
  gem "rspec-benchmark", "~> 0.6.0"
end
