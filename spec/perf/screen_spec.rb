# frozen_string_literal: true

require "io/console"
require "rspec-benchmark"

RSpec.describe TTY::Screen do
  include RSpec::Benchmark::Matchers

  describe ".size" do
    it "detects size 14.5x slower than io-console" do
      expect {
        TTY::Screen.size
      }.to perform_slower_than {
        IO.console.winsize
      }.at_most(14.5).times
    end

    it "performs at least 175K i/s" do
      expect { TTY::Screen.size }.to perform_at_least(175_000).ips
    end

    it "allocates 8 objects" do
      expect { TTY::Screen.size }.to perform_allocation(8).objects
    end
  end

  describe ".size_from_io_console" do
    it "performs at least 1.45M i/s" do
      expect {
        TTY::Screen.size_from_io_console
      }.to perform_at_least(1_450_000).ips
    end

    it "allocates 1 object" do
      expect {
        TTY::Screen.size_from_io_console
      }.to perform_allocation(1).objects
    end

    it "allocates 1 Array object" do
      expect {
        TTY::Screen.size_from_io_console
      }.to perform_allocation({Array => 1}).objects
    end
  end

  describe ".size_from_ioctl" do
    it "performs at least 175K i/s" do
      expect {
        TTY::Screen.size_from_ioctl
      }.to perform_at_least(175_000).ips
    end

    it "allocates 8 objects" do
      expect {
        TTY::Screen.size_from_ioctl
      }.to perform_allocation(8).objects
    end

    it "allocates 3 Array, 3 String and 2 other object" do
      expect {
        TTY::Screen.size_from_ioctl
      }.to perform_allocation({
        Array => 3, Errno::ENOTTY => 1, String => 3, Thread::Backtrace => 1
      }).objects
    end
  end

  describe ".size_from_tput" do
    it "performs at least 400 i/s" do
      expect {
        TTY::Screen.size_from_tput
      }.to perform_at_least(400).ips
    end

    it "allocates 67 objects" do
      expect {
        TTY::Screen.size_from_tput
      }.to perform_allocation(67).objects
    end

    it "allocates 15 Array, 46 String and 6 other objects" do
      expect {
        TTY::Screen.size_from_tput
      }.to perform_allocation({
        Array => 15, Hash => 2, IO => 2, Process::Status => 2, String => 46
      }).objects
    end
  end

  describe ".size_from_stty" do
    it "performs at least 850 i/s" do
      expect {
        TTY::Screen.size_from_stty
      }.to perform_at_least(850).ips
    end

    it "allocates 65 objects" do
      expect {
        TTY::Screen.size_from_stty
      }.to perform_allocation(65).objects
    end

    it "allocates 16 Array, 46 String and 3 other objects" do
      expect {
        TTY::Screen.size_from_stty
      }.to perform_allocation({
        Array => 16, Hash => 1, IO => 1, Process::Status => 1, String => 46
      }).objects
    end
  end

  describe ".size_from_env" do
    around do |test|
      original_env = TTY::Screen.env
      TTY::Screen.env = {"LINES" => "51", "COLUMNS" => "211"}
      test.run
      TTY::Screen.env = original_env
    end

    it "performs at least 2.75M i/s" do
      expect {
        TTY::Screen.size_from_env
      }.to perform_at_least(2_750_000).ips
    end

    it "allocates 2 objects" do
      expect {
        TTY::Screen.size_from_env
      }.to perform_allocation(2).objects
    end

    it "allocates 1 Array and 1 MatchData object" do
      expect {
        TTY::Screen.size_from_env
      }.to perform_allocation({Array => 1, MatchData => 1}).objects
    end
  end

  describe ".size_from_ansicon" do
    around do |test|
      original_env = TTY::Screen.env
      TTY::Screen.env = {"ANSICON" => "(51x211)"}
      test.run
      TTY::Screen.env = original_env
    end

    it "performs at least 1.9M i/s" do
      expect {
        TTY::Screen.size_from_ansicon
      }.to perform_at_least(1_900_000).ips
    end

    it "allocates 4 objects" do
      expect {
        TTY::Screen.size_from_ansicon
      }.to perform_allocation(4).objects
    end

    it "allocates 1 Array, 1 MatchData and 2 String objects" do
      expect {
        TTY::Screen.size_from_ansicon
      }.to perform_allocation({
        Array => 1, MatchData => 1, String => 2
      }).objects
    end
  end
end
