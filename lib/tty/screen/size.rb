module TTY
  class Screen
    class Size
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
        size =   from_io_console
        size ||= from_readline
        size ||= from_tput
        size ||= from_stty
        size ||= from_env
        size ||= from_ansicon
        size ||  default_size
      end

      # Detect screen size by loading io/console lib
      #
      # @return [Array[Integer, Integer]]
      #
      # @api private
      def from_io_console
        return if jruby?
        try_io_console { |size| size if nonzero_column?(size[1]) }
      end

      # Attempts to load native console extension
      #
      # @return [Boolean, Array]
      #
      # @api private
      def try_io_console
        require 'io/console'

        begin
          if output.tty? && IO.method_defined?(:winsize)
            yield output.winsize
          end
        rescue Errno::EOPNOTSUPP
          # no support for winsize on output
        end
      rescue LoadError
        warn 'no native io/console support or io-console gem' if @verbose
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

      # Default terminal size
      #
      # @api public
      def default_size
        [
          @env['LINES'].to_i.nonzero? || 27,
          @env['COLUMNS'].to_i.nonzero? || 80
        ]
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
