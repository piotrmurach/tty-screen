# coding: utf-8

module TTY
  class Screen
    class Color

      # Initialize color support
      #
      # @api public
      def initialize(options = {})
        @output = options.fetch(:output) { $stderr }
      end

      # Detect if terminal supports color
      #
      # @return [Boolean]
      #   true when terminal supports color, false otherwise
      #
      # @api public
      def supports?
        return false unless tty?

        from_curses || from_tput || from_term || from_env
      end

      # Attempt to load curses to check color support
      #
      # @return [Boolean]
      #
      # @api private
      def from_curses(curses_class = nil)
        begin
          require 'curses'

          begin
            curses_class ||= Curses
            curses_class.init_screen
            curses_class.has_colors?
          ensure
            curses_class.close_screen
          end
        rescue LoadError
          warn 'no native curses support' if $VERBOSE
          false
        end
      end

      # Shell out to tput to check color support
      #
      # @api private
      def from_tput
        %x(tput colors 2>/dev/null).to_i > 2
      end

      # Inspect environment $TERM variable for color support
      #
      # @api private
      def from_term
        if ENV['TERM'] == 'dumb'
          false
        elsif ENV['TERM'] =~ /^screen|^xterm|^vt100|color|ansi|cygwin|linux/i
          true
        else false
        end
      end

      def from_env
        ENV.include?('COLORTERM')
      end

      attr_reader :output

      def tty?
        output.tty?
      end
    end
  end
end # TTY
