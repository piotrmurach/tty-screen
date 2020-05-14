source "https://rubygems.org"

gemspec

gem "coveralls", "~> 0.8.22"
gem "simplecov", "~> 0.16.1"
gem "yardstick", "~> 0.9.9"
if RUBY_VERSION.split(".")[1].to_i > 0 && !(/jruby/ =~ RUBY_ENGINE)
  gem "rspec-benchmark", "~> 0.6.0"
end
if RUBY_VERSION.split(".")[1].to_i > 3 && !(/jruby/ =~ RUBY_ENGINE)
  gem "io-console"
end
