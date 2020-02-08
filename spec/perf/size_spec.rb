# frozen_string_literal: true

require "io/console"
require "rspec-benchmark"

RSpec.describe TTY::Screen, ".size" do
  include RSpec::Benchmark::Matchers

  it "detectes size 15x slower than io-console" do
    expect {
      TTY::Screen.size
    }.to perform_slower_than {
      IO.console.winsize
    }.at_most(15).times
  end

  it "performs at least 27K i/s" do
    expect { TTY::Screen.size }.to perform_at_least(27_000).ips
  end

  it "allocates at most 11 objects" do
    expect { TTY::Screen.size }.to perform_allocation(13).objects
  end
end
