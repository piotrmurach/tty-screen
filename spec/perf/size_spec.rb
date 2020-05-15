# frozen_string_literal: true

require "io/console"
require "rspec-benchmark"

RSpec.describe TTY::Screen, ".size" do
  include RSpec::Benchmark::Matchers

  it "detectes size 13x slower than io-console" do
    expect {
      TTY::Screen.size
    }.to perform_slower_than {
      IO.console.winsize
    }.at_most(13).times
  end

  it "performs at least 28K i/s" do
    expect { TTY::Screen.size }.to perform_at_least(28_000).ips
  end

  it "allocates at most 10 objects" do
    expect { TTY::Screen.size }.to perform_allocation(10).objects
  end
end
