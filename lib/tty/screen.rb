# coding: utf-8

require 'tty/screen/version'

module TTY
  # Used for detecting screen properties
  #
  # @api public
  class Screen
    # Specifies an output stream object
    #
    # @api public
    attr_reader :output

    # Create terminal screen
    #
    # @param [Hash] options
    # @option options [Object] :output
    #   the object that responds to print call defaulting to stderr
    #
    # @api public
    def initialize(options = {})
      @output = options.fetch(:output) { $stderr }
    end

    def self.size
      @size ||= new.size
    end

    def self.width
      size[1]
    end

    def self.height
      size[0]
    end

    # Get terminal rows and columns
    #
    # @return [Array[Integer, Integer]]
    #   return rows & columns
    #
    # @api public
    def size
      @size ||= begin
        size = from_io_console
        size ||= from_readline
        size ||= from_tput
        size ||= from_stty
        size ||= from_env
        size ||= from_ansicon
        size || default_size
      end
    end

    # Default terminal size
    #
    # @api public
    def default_size
      [27, 80]
    end

    def height
      size[0]
    end
    alias_method :rows, :height

    def width
      size[1]
    end
    alias_method :columns, :width

    # Detect screen size by loading io/console lib
    #
    # @return [Array[Integer, Integer]]
    #
    # @api private
    def from_io_console
      return if jruby?
      Kernel.require 'io/console'
      return unless IO.console
      size = IO.console.winsize
      size if nonzero_column?(size[1])
    rescue LoadError
      # Didn't find io/console in stdlib
    end

    # Detect screen size using Readline
    #
    #
    # @api private
    def from_readline
      return unless defined?(Readline)
      size = Readline.get_screen_size
      size if nonzero_column?(size[1])
    rescue NotImplementedError
    end

    # Detect terminal size from tput utility
    #
    # @api public
    def from_tput
      return unless output.tty?
      lines = run_command('tput', 'lines').to_i
      cols  = run_command('tput', 'cols').to_i
      [lines, cols] if nonzero_column?(lines)
    rescue Errno::ENOENT
    end

    # Detect terminal size from stty utility
    #
    # @api public
    def from_stty
      return unless output.tty?
      size = run_command('stty', 'size').split.map(&:to_i)
      size if nonzero_column?(size[1])
    rescue Errno::ENOENT
    end

    # Detect terminal size from environment
    #
    # @api private
    def from_env
      return unless ENV['COLUMNS'] =~ /^\d+$/
      size = [(ENV['LINES'] || ENV['ROWS']).to_i, ENV['COLUMNS'].to_i]
      size if nonzero_column?(size[1])
    end

    # Detect terminal size on windows
    #
    # @api private
    def from_ansicon
      return unless ENV['ANSICON'] =~ /\((.*)x(.*)\)/
      size = [$2, $1].map(&:to_i)
      size if nonzero_column?(size[1])
    end

    # Runs command in subprocess
    #
    # @api public
    def run_command(command, name)
      `#{command} #{name} 2>/dev/null`
    end

    private

    def nonzero_column?(column)
      column.to_i > 0
    end

    def jruby?
      RbConfig::CONFIG['ruby_install_name'] == 'jruby'
    end
  end # Screen
end # TTY
