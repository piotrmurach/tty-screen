# frozen_string_literal: true

require "io/console"
require "rspec-benchmark"

RSpec.describe TTY::Screen, ".size" do
  include RSpec::Benchmark::Matchers

  it "detectes size 180x slower than io-console" do
    expect {
      TTY::Screen.size
    }.to perform_slower_than {
      IO.console.winsize
    }.at_most(180).times
  end

  it "performs at least 2K i/s" do
    expect { TTY::Screen.size }.to perform_at_least(2000).ips
  end

  it "allocates at most 366 objects" do
    expect { TTY::Screen.size }.to perform_allocation(366).objects
  end
end
