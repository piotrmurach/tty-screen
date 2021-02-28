source "https://rubygems.org"

gemspec

gem "coveralls", "~> 0.8.22"
gem "simplecov", "~> 0.16.1"
gem "json", "2.4.1" if RUBY_VERSION == "2.0.0"
gem "yardstick", "~> 0.9.9"

if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("2.1.0") &&
   !(/jruby/ =~ RUBY_ENGINE)
  gem "rspec-benchmark", "~> 0.6.0"
end
if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("2.4.0") &&
   !(/jruby/ =~ RUBY_ENGINE)
  gem "io-console"
end
