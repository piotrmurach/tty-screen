# coding: utf-8

require 'tty/screen/color'
require 'tty/screen/size'
require 'tty/screen/version'

module TTY
  # Used for detecting screen properties
  #
  # @api public
  class Screen
    # Create terminal screen
    #
    # @param [Hash] options
    # @option options [Object] :output
    #   the object that responds to print call defaulting to stderr
    #
    # @api public
    def initialize(options = {})
      @output = options.fetch(:output) { $stderr }
      @color  = Color.new(output: @output)
      @size   = Size.new(output: @output)
    end

    # @api public
    def self.size
      new.size
    end

    # @api public
    def self.width
      size[1]
    end

    # @api public
    def self.height
      size[0]
    end

    def self.color?
      new.color?
    end

    def size
      @size.size
    end

    # Terminal lines count
    #
    # @return [Integer]
    #
    # @api public
    def height
      size[0]
    end
    alias_method :rows, :height

    # Terminal columns count
    #
    # @return [Integer]
    #
    # @api public
    def width
      size[1]
    end
    alias_method :columns, :width

    # Check if terminal has color support
    #
    # @return [Boolean]
    #   true if can display color, false otherwise
    #
    # @api public
    def color?
      @color.supports?
    end
  end # Screen
end # TTY
