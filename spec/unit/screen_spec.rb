# frozen_string_literal: true

require "delegate"
require "readline"
require "stringio"

RSpec.describe TTY::Screen do
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
    it "doesn't detect size on non-tty output" do
      allow(screen.output).to receive(:tty?).and_return(false)

      expect(screen.size_from_io_console).to eq(nil)
      expect(screen.output).to have_received(:tty?)
    end

    it "doesn't detect size when the io/console fails to load" do
      allow(screen.output).to receive(:tty?).and_return(true)
      allow(IO).to receive(:method_defined?).with(:winsize).and_return(false)
      allow(screen).to receive(:require).with("io/console").and_raise(LoadError)

      expect(screen.size_from_io_console).to eq(nil)
      expect(IO).to have_received(:method_defined?).with(:winsize)
      expect(screen).to have_received(:require).with("io/console")
    end

    it "warns in verbose mode when the io/console fails to load" do
      allow(screen.output).to receive(:tty?).and_return(true)
      allow(IO).to receive(:method_defined?).with(:winsize).and_return(false)
      allow(screen).to receive(:require).with("io/console").and_raise(LoadError)

      expect {
        screen.size_from_io_console(verbose: true)
      }.to output("no native io/console support or io-console gem\n").to_stderr
    end

    it "doesn't detect size when the winsize method is missing" do
      allow(screen.output).to receive(:tty?).and_return(true)
      allow(IO).to receive(:method_defined?).with(:winsize).and_return(true)
      allow(screen.output).to receive(:respond_to?)
        .with(:winsize).and_return(false)

      expect(screen.size_from_io_console).to eq(nil)
      expect(screen.output).to have_received(:respond_to?).with(:winsize)
    end

    it "doesn't detect size when the winsize method raises an error" do
      allow(IO).to receive(:method_defined?).with(:winsize).and_return(true)
      allow(screen.output).to receive_messages(tty?: true, respond_to?: true)
      allow(screen.output).to receive(:winsize).and_raise(Errno::EOPNOTSUPP)

      expect(screen.size_from_io_console).to eq(nil)
      expect(screen.output).to have_received(:winsize)
    end

    it "detects no columns" do
      allow(IO).to receive(:method_defined?).with(:winsize).and_return(true)
      allow(screen.output).to receive_messages(
        tty?: true, respond_to?: true, winsize: [51, 0])

      expect(screen.size_from_io_console).to eq(nil)
      expect(screen.output).to have_received(:winsize)
    end

    it "detects size" do
      allow(IO).to receive(:method_defined?).with(:winsize).and_return(true)
      allow(screen.output).to receive_messages(
        tty?: true, respond_to?: true, winsize: [51, 211])

      expect(screen.size_from_io_console).to eq([51, 211])
    end
  end

  describe "#size_from_ioctl",
    unless: TTY::Screen.jruby? || TTY::Screen.windows? do
    before do
      stub_const("Output", Class.new(SimpleDelegator) do
        def winsize
          [100, 200]
        end

        def big_endian?
          [1].pack("S") == [1].pack("n")
        end

        def ioctl(_control, buf)
          little_endian = "3\x00\xD3\x00\xF2\x04\xCA\x02\x00"
          big_endian = "\x003\x00\xD3\x04\xF2\x02\xCA"
          buf.replace(big_endian? ? big_endian : little_endian)
          0
        end
      end)
    end

    it "doesn't detect size with the Linux get window size command" do
      allow(screen).to receive(:ioctl?).and_return(false)

      expect(screen.size_from_ioctl).to eq(nil)
      expect(screen).to have_received(:ioctl?).with(0x5413, anything)
    end

    it "doesn't detect size with the FreeBSD get window size command" do
      allow(screen).to receive(:ioctl?).and_return(false)

      expect(screen.size_from_ioctl).to eq(nil)
      expect(screen).to have_received(:ioctl?).with(0x40087468, anything)
    end

    it "doesn't detect size with the Solaris get window size command" do
      allow(screen).to receive(:ioctl?).and_return(false)

      expect(screen.size_from_ioctl).to eq(nil)
      expect(screen).to have_received(:ioctl?).with(0x5468, anything)
    end

    it "doesn't detect size when the ioctl system call fails" do
      output = double(:output, write: nil, ioctl: -1)

      replace_standard_streams(output) do
        expect(screen.size_from_ioctl).to eq(nil)
        expect(output).to have_received(:ioctl).exactly(9).times
      end
    end

    it "doesn't detect size when the ioctl system call raises an error" do
      output = double(:output, write: nil)
      allow(output).to receive(:ioctl).and_raise(Errno::EOPNOTSUPP)

      replace_standard_streams(output) do
        expect(screen.size_from_ioctl).to eq(nil)
        expect(output).to have_received(:ioctl).exactly(3).times
      end
    end

    it "detects no columns" do
      allow(screen).to receive(:ioctl?).and_return(true)

      expect(screen.size_from_ioctl).to eq(nil)
    end

    it "detects size" do
      replace_standard_streams(Output.new(StringIO.new)) do
        expect(screen.size_from_ioctl).to eq([51, 211])
      end
    end
  end

  describe "#size_from_ioctl", if: TTY::Screen.jruby? do
    it "doesn't detect size on JRuby", if: TTY::Screen.jruby? do
      expect(screen.size_from_ioctl).to eq(nil)
    end
  end

  describe "#size_from_readline" do
    it "doesn't detect size on non-tty output" do
      allow(screen.output).to receive(:tty?).and_return(false)

      expect(screen.size_from_readline).to eq(nil)
      expect(screen.output).to have_received(:tty?)
    end

    it "doesn't detect size when the readline fails to load" do
      undefine_const(:Readline) do
        allow(screen.output).to receive(:tty?).and_return(true)
        allow(screen).to receive(:require).with("readline").and_raise(LoadError)

        expect(screen.size_from_readline).to eq(nil)
        expect(screen).to have_received(:require).with("readline")
      end
    end

    it "warns in verbose mode when the readline fails to load" do
      undefine_const(:Readline) do
        allow(screen.output).to receive(:tty?).and_return(true)
        allow(screen).to receive(:require).with("readline").and_raise(LoadError)

        expect {
          screen.size_from_readline(verbose: true)
        }.to output("no readline gem\n").to_stderr
      end
    end

    it "doesn't detect size when the get_screen_size method is missing" do
      allow(screen.output).to receive(:tty?).and_return(true)
      allow(Readline).to receive(:respond_to?)
        .with(:get_screen_size).and_return(false)

      expect(screen.size_from_readline).to eq(nil)
      expect(Readline).to have_received(:respond_to?).with(:get_screen_size)
    end

    it "doesn't detect size when the get_screen_size method raises an error" do
      allow(screen.output).to receive(:tty?).and_return(true)
      allow(Readline).to receive(:respond_to?).and_return(true)
      allow(Readline).to receive(:get_screen_size)
        .and_raise(NotImplementedError)

      expect(screen.size_from_readline).to eq(nil)
      expect(Readline).to have_received(:get_screen_size)
    end

    it "detects no columns" do
      allow(screen.output).to receive(:tty?).and_return(true)
      allow(Readline).to receive_messages(
        respond_to?: true, get_screen_size: [51, 0])

      expect(screen.size_from_readline).to eq(nil)
      expect(Readline).to have_received(:get_screen_size)
    end

    it "detects size" do
      allow(screen.output).to receive(:tty?).and_return(true)
      allow(Readline).to receive_messages(
        respond_to?: true, get_screen_size: [51, 211])

      expect(screen.size_from_readline).to eq([51, 211])
    end
  end

  describe "#size_from_tput" do
    it "doesn't detect size on non-tty output" do
      allow(screen.output).to receive(:tty?).and_return(false)

      expect(screen.size_from_tput).to eq(nil)
    end

    it "doesn't detect size when the tput command is missing" do
      path = "/usr/bin/tput"
      allow(screen.output).to receive(:tty?).and_return(true)
      allow(screen.env).to receive(:fetch)
        .with("PATHEXT", "").and_return(".exe")
      allow(screen.env).to receive(:fetch)
        .with("PATH", "").and_return("/usr/bin")
      allow(File).to receive(:join).with("/usr/bin", "tput").and_return(path)
      allow(File).to receive(:exist?).with(path).and_return(false)
      allow(File).to receive(:exist?).with("#{path}.exe").and_return(false)

      expect(screen.size_from_tput).to eq(nil)
      expect(File).to have_received(:exist?).with(path)
      expect(File).to have_received(:exist?).with("#{path}.exe")
    end

    it "doesn't detect size when the tput command raises an IO error" do
      allow(screen.output).to receive(:tty?).and_return(true)
      allow(screen).to receive(:command_exist?).with("tput").and_return(true)
      allow(screen).to receive(:`).with("tput lines").and_raise(IOError)

      expect(screen.size_from_tput).to eq(nil)
      expect(screen).to have_received(:`).with("tput lines")
    end

    it "doesn't detect size when the tput command raises a system error" do
      allow(screen.output).to receive(:tty?).and_return(true)
      allow(screen).to receive(:command_exist?).with("tput").and_return(true)
      allow(screen).to receive(:`).with("tput lines").and_raise(Errno::ENOENT)

      expect(screen.size_from_tput).to eq(nil)
      expect(screen).to have_received(:`).with("tput lines")
    end

    it "detects no lines" do
      allow(screen.output).to receive(:tty?).and_return(true)
      allow(screen).to receive(:command_exist?).with("tput").and_return(true)
      allow(screen).to receive(:`).with("tput lines").and_return(nil)

      expect(screen.size_from_tput).to eq(nil)
      expect(screen).to have_received(:`).with("tput lines")
    end

    it "detects zero lines" do
      allow(screen.output).to receive(:tty?).and_return(true)
      allow(screen).to receive(:command_exist?).with("tput").and_return(true)
      allow(screen).to receive(:`).with("tput lines").and_return("0")
      allow(screen).to receive(:`).with("tput cols").and_return("0")

      expect(screen.size_from_tput).to eq(nil)
      expect(screen).to have_received(:`).with("tput lines")
      expect(screen).to have_received(:`).with("tput cols")
    end

    it "detects size" do
      allow(screen.output).to receive(:tty?).and_return(true)
      allow(screen).to receive(:command_exist?).with("tput").and_return(true)
      allow(screen).to receive(:`).with("tput lines").and_return("51")
      allow(screen).to receive(:`).with("tput cols").and_return("211")

      expect(screen.size_from_tput).to eq([51, 211])
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
