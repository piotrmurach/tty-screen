# frozen_string_literal: true

module TTY
  class Screen
    class Size
      # Default terminal size
      #
      # @api public
      DEFAULT_SIZE = [27, 80].freeze

      # Initialize terminal size detection
      #
      # @api public
      def initialize(env, options = {})
        @env     = env
        @output  = options.fetch(:output) { $stderr }
        @verbose = options.fetch(:verbose) { false }
      end

      # Get terminal rows and columns
      #
      # @return [Array[Integer, Integer]]
      #   return rows & columns
      #
      # @api public
      def size
        size = from_java
        size ||= from_io_console
        size ||= from_ioctl
        size ||= from_readline
        size ||= from_tput
        size ||= from_stty
        size ||= from_env
        size ||= from_ansicon
        size ||  DEFAULT_SIZE
      end

      # Determine terminal size on jruby using native Java libs
      #
      # @return [nil, Array[Integer, Integer]]
      #
      # @api private
      def from_java
        return unless jruby?
        require 'java'
        java_import 'jline.TerminalFactory'
        terminal = TerminalFactory.get
        [terminal.get_height, terminal.get_width]
      rescue
        warn 'failed to import java terminal package' if @verbose
      end

      # Detect screen size by loading io/console lib
      #
      # @return [nil, Array[Integer, Integer]]
      #
      # @api private
      def from_io_console
        return if jruby?
        require 'io/console'

        begin
          if output.tty? && IO.method_defined?(:winsize)
            size = output.winsize
            size if nonzero_column?(size[1])
          end
        rescue Errno::EOPNOTSUPP
          # no support for winsize on output
        end
      rescue LoadError
        warn 'no native io/console support or io-console gem' if @verbose
      end

      TIOCGWINSZ = 0x5413
      TIOCGWINSZ_PPC = 0x40087468

      # Read terminal size from Unix ioctl
      #
      # @return [nil, Array[Integer, Integer]]
      #
      # @api private
      def from_ioctl
        return if jruby?
        return unless output.respond_to?(:ioctl)

        buffer = [0, 0, 0, 0].pack('SSSS')
        if ioctl?(TIOCGWINSZ, buffer) || ioctl?(TIOCGWINSZ_PPC, buffer)
          rows, cols, = buffer.unpack('SSSS')[0..1]
          return [rows, cols]
        end
      end

      def ioctl?(control, buf)
        output.ioctl(control, buf) >= 0
      rescue Errno::ENOTTY
        # wrong processor architecture
        false
      rescue Errno::EINVAL
        # ioctl failed to recognise processor type(not Intel)
        false
      end

      # Detect screen size using Readline
      #
      # @api private
      def from_readline
        if defined?(Readline) && Readline.respond_to?(:get_screen_size)
          size = Readline.get_screen_size
          size if nonzero_column?(size[1])
        end
      rescue NotImplementedError
      end

      # Detect terminal size from tput utility
      #
      # @api private
      def from_tput
        return unless output.tty?
        lines = run_command('tput', 'lines').to_i
        cols  = run_command('tput', 'cols').to_i
        [lines, cols] if nonzero_column?(lines)
      rescue Errno::ENOENT
      end

      # Detect terminal size from stty utility
      #
      # @api private
      def from_stty
        return unless output.tty?
        out = run_command('stty', 'size')
        return unless out
        size = out.split.map(&:to_i)
        size if nonzero_column?(size[1])
      rescue Errno::ENOENT
      end

      # Detect terminal size from environment
      #
      # @api private
      def from_env
        return unless @env['COLUMNS'] =~ /^\d+$/
        size = [(@env['LINES'] || @env['ROWS']).to_i, @env['COLUMNS'].to_i]
        size if nonzero_column?(size[1])
      end

      # Detect terminal size on windows
      #
      # @api private
      def from_ansicon
        return unless @env['ANSICON'] =~ /\((.*)x(.*)\)/
        size = [$2, $1].map(&:to_i)
        size if nonzero_column?(size[1])
      end

      # Specifies an output stream object
      #
      # @api public
      attr_reader :output

      private

      # Runs command silently capturing the output
      #
      # @api private
      def run_command(*args)
        require 'tempfile'
        out = Tempfile.new('tty-screen')
        result = system(*args, out: out.path)
        return if result.nil?
        out.rewind
        out.read
      ensure
        out.close if out
      end

      # Check if number is non zero
      #
      # return [Boolean]
      #
      # @api private
      def nonzero_column?(column)
        column.to_i > 0
      end

      def jruby?
        RbConfig::CONFIG['ruby_install_name'] == 'jruby'
      end
    end # Size
  end # Screen
end # TTY
