require "delegate"
require "stringio"

RSpec.describe TTY::Screen do
  class Output < SimpleDelegator
    def winsize
      [100, 200]
    end

    def big_endian?
      [1].pack("S") == [1].pack("n")
    end

    def ioctl(control, buf)
      little_endian = "3\x00\xD3\x00\xF2\x04\xCA\x02\x00"
      big_endian = "\x003\x00\xD3\x04\xF2\x02\xCA"
      buf.replace(big_endian? ? big_endian : little_endian)
      0
    end
  end

  let(:output) { Output.new(StringIO.new("", "w+")) }

  subject(:screen) { described_class }

  describe "#size" do
    it "correctly falls through choices" do
      old_output = screen.output
      screen.output = StringIO.new

      {
        size_from_java: nil,
        size_from_win_api: nil,
        size_from_ioctl: nil,
        size_from_io_console: [51, 280],
        size_from_readline: nil
      }.each do |size_method, result|
        allow(screen).to receive(size_method) { result }
      end

      expect(screen.size).to eq([51, 280])
      expect(screen).to have_received(:size_from_java)
      expect(screen).to have_received(:size_from_win_api)
      expect(screen).to have_received(:size_from_ioctl)
      expect(screen).to_not have_received(:size_from_readline)

      screen.output = old_output
    end
  end

  describe "#size_from_win_api" do
    it "doesn't check size on non-windows platform", unless: TTY::Screen.windows? do
      expect(screen.size_from_win_api).to eq(nil)
    end
  end

  describe "#size_from_java" do
    it "doesn't import java on non-jruby platform", unless: TTY::Screen.jruby? do
      expect(screen.size_from_java).to eq(nil)
    end

    it "imports java library on jruby", if: TTY::Screen.jruby? do
      class << screen
        def java_import(*args); end
      end
      terminal = double(:terminal, get_height: 51, get_width: 211)
      factory = double(:factory, get: terminal)
      stub_const("TTY::Screen::TerminalFactory", factory)

      allow(screen).to receive(:jruby?).and_return(true)
      allow(screen).to receive(:require).with("java").and_return(true)
      allow(screen).to receive(:java_import)

      expect(screen.size_from_java).to eq([51, 211])
    end
  end

  describe "#size_from_io_console" do
    it "calcualtes the size" do
      old_output = screen.output
      screen.output = StringIO.new

      allow(IO).to receive(:method_defined?).with(:winsize) { true }
      allow(screen.output).to receive(:tty?) { true }
      allow(screen.output).to receive(:respond_to?) { true }
      allow(screen.output).to receive(:winsize) { [100, 200] }

      expect(screen.size_from_io_console).to eq([100, 200])
      expect(screen.output).to have_received(:winsize)

      screen.output = old_output
    end

    it "doesn't calculate size if io/console not available" do
      allow(IO).to receive(:method_defined?).with(:winsize).and_return(false)
      allow(screen).to receive(:require).with("io/console").and_raise(LoadError)

      expect(screen.size_from_io_console).to eq(nil)
    end

    it "doesn't calculate size if it is run without a console" do
      allow(IO).to receive(:method_defined?).with(:winsize) { true }
      allow(screen).to receive(:require).with("io/console") { true }
      allow(screen.output).to receive(:tty?) { true }
      allow(screen.output).to receive(:respond_to?).with(:winsize) { false }

      expect(screen.size_from_io_console).to eq(nil)
    end
  end

  describe "#size_from_ioctl" do
    def replace_streams(*streams)
      originals = [$stdout, $stdin, $stderr]
      $stdout, $stdin, $stderr = output, output, output
      yield
    ensure
      $stdout, $stdin, $stderr = *originals
    end

    it "reads terminal size", unless: TTY::Screen.windows? || TTY::Screen.jruby? do
      replace_streams do
        expect(screen.size_from_ioctl).to eq([51, 211])
      end
    end

    it "skips reading on jruby", if: TTY::Screen.jruby? do
      expect(screen.size_from_ioctl).to eq(nil)
    end
  end

  describe "#size_from_tput" do
    it "doesn't run command if outside of terminal" do
      allow(screen.output).to receive(:tty?).and_return(false)
      expect(screen.size_from_tput).to eq(nil)
    end

    it "doesn't run command if not available" do
      allow(screen).to receive(:command_exist?).and_return(false)
      expect(screen.size_from_tput).to eq(nil)
    end

    it "runs tput commands" do
      allow(screen.output).to receive(:tty?).and_return(true)
      allow(screen).to receive(:command_exist?).with("tput").and_return(true)
      allow(screen).to receive(:run_command).with("tput", "lines").and_return(51)
      allow(screen).to receive(:run_command).with("tput", "cols").and_return(280)

      expect(screen.size_from_tput).to eq([51, 280])
    end

    it "doesn't return zero size" do
      allow(screen.output).to receive(:tty?).and_return(true)
      allow(screen).to receive(:command_exist?).with("tput").and_return(true)
      allow(screen).to receive(:run_command).with("tput", "lines").and_return(0)
      allow(screen).to receive(:run_command).with("tput", "cols").and_return(0)

      expect(screen.size_from_tput).to eq(nil)
    end
  end

  describe "#size_from_stty" do
    it "doesn't run command if outside of terminal" do
      allow(screen.output).to receive(:tty?).and_return(false)
      expect(screen.size_from_stty).to eq(nil)
    end

    it "doesn't run command if not available" do
      allow(screen).to receive(:command_exist?).and_return(false)
      expect(screen.size_from_stty).to eq(nil)
    end

    it "runs stty commands" do
      allow(screen.output).to receive(:tty?).and_return(true)
      allow(screen).to receive(:command_exist?).with("stty").and_return(true)
      allow(screen).to receive(:run_command).with("stty", "size").and_return("51 280")

      expect(screen.size_from_stty).to eq([51, 280])
    end

    it "doesn't return zero size" do
      allow(screen.output).to receive(:tty?).and_return(true)
      allow(screen).to receive(:command_exist?).with("stty").and_return(true)
      allow(screen).to receive(:run_command).with("stty", "size").and_return("0 0")

      expect(screen.size_from_stty).to eq(nil)
    end
  end

  describe "#size_from_env" do
    it "doesn't calculate size without COLUMNS key" do
      old_env = screen.env
      screen.env = {"COLUMNS" => nil}
      expect(screen.size_from_env).to eq(nil)
      screen.env = old_env
    end

    it "extracts lines and columns from environment" do
      old_env = screen.env
      screen.env = {"COLUMNS" => "280", "LINES" => "51"}
      expect(screen.size_from_env).to eq([51, 280])
      screen.env = old_env
    end

    it "doesn't return zero size" do
      old_env = screen.env
      screen.env = {"COLUMNS" => "0", "LINES" => "0"}
      expect(screen.size_from_env).to eq(nil)
      screen.env = old_env
    end
  end

  describe "#size_from_ansicon" do
    it "doesn't calculate size without ANSICON key" do
      old_env = screen.env
      screen.env = {"ANSICON" => nil}
      expect(screen.size_from_ansicon).to eq(nil)
      screen.env = old_env
    end

    it "extracts lines and columns from environment" do
      old_env = screen.env
      screen.env = {"ANSICON" => "(280x51)"}
      expect(screen.size_from_ansicon).to eq([51, 280])
      screen.env = old_env
    end

    it "doesn't return zero size" do
      old_env = screen.env
      screen.env = {"ANSICON" => "(0x0)"}
      expect(screen.size_from_ansicon).to eq(nil)
      screen.env = old_env
    end
  end

  describe "#size_from_default" do
    it "suggests default terminal size" do
      [:size_from_java,
       :size_from_win_api,
       :size_from_ioctl,
       :size_from_io_console,
       :size_from_readline,
       :size_from_tput,
       :size_from_stty,
       :size_from_env,
       :size_from_ansicon].each do |method|
        allow(screen).to receive(method).and_return(nil)
       end
      expect(screen.size).to eq([27, 80])
    end
  end

  describe "#width" do
    it "calcualtes screen width" do
      allow(screen).to receive(:size).and_return([51, 280])

      expect(screen.width).to eq(280)
    end

    it "aliases width to columns and cols" do
      allow(screen).to receive(:size).and_return([51, 280])

      expect(screen.columns).to eq(280)
      expect(screen.cols).to eq(280)
    end
  end

  describe "#height" do
    it "calcualtes screen height" do
      allow(screen).to receive(:size).and_return([51, 280])

      expect(screen.height).to eq(51)
    end

    it "aliases width to rows and lines" do
      allow(screen).to receive(:size).and_return([51, 280])

      expect(screen.rows).to eq(51)
      expect(screen.lines).to eq(51)
    end
  end
end
