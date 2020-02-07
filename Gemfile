source "https://rubygems.org"

gemspec

gem "rspec", "~> 3.1"
gem "rake"
gem "coveralls", "~> 0.8.22"
gem "simplecov", "~> 0.16.1"
gem "yardstick", "~> 0.9.9"
if RUBY_VERSION.split(".")[1].to_i > 0
  gem "rspec-benchmark", git: "https://github.com/piotrmurach/rspec-benchmark"
end
if RUBY_VERSION.split(".")[1].to_i > 3
  gem "io-console"
end
