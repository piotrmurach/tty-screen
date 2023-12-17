# frozen_string_literal: true

if ENV["COVERAGE"] == "true"
  require "simplecov"
  require "coveralls"

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ])

  SimpleCov.start do
    command_name "spec"
    add_filter "spec"
    enable_coverage :branch
  end
end

module Helpers
  # Replace standard streams
  #
  # @example
  #   replace_standard_streams(StringIO.new) do
  #     ...
  #   end
  #
  # @param [StringIO] output
  #   the output to replace standard streams with
  #
  # @return [void]
  #
  # @api public
  def replace_standard_streams(output)
    original_streams = [$stdin, $stdout, $stderr]
    $stdin, $stdout, $stderr = output, output, output
    yield
  ensure
    $stdin, $stdout, $stderr = *original_streams
  end

  # Undefine a constant
  #
  # @example
  #   undefine_const(:Readline) do
  #     ...
  #   end
  #
  # @param [String, Symbol] name
  #   the constant name
  #
  # @return [void]
  #
  # @api public
  def undefine_const(name)
    if Object.const_defined?(name)
      const = Object.send(:remove_const, name)
    end
    yield
  ensure
    Object.const_set(name, const) if const
  end
end

require "tty-screen"

RSpec.configure do |config|
  config.include(Helpers)

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # Limits the available syntax to the non-monkey patched syntax
  # that is recommended.
  config.disable_monkey_patching!

  # This setting enables warnings. It's recommended, but in some cases may
  # be too noisy due to issues in dependencies.
  config.warnings = true

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  config.profile_examples = 2

  config.order = :random

  Kernel.srand config.seed
end
