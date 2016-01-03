# coding: utf-8

require 'delegate'

RSpec.describe TTY::Screen::Size, '#size' do
  class Output < SimpleDelegator
    def winsize
      [100, 200]
    end
  end

  let(:output) { Output.new(StringIO.new('', 'w+')) }

  context 'size' do
    it "correctly falls through choices" do
      screen = described_class.new({}, output: output)
      allow(screen).to receive(:from_io_console).and_return([51, 280])
      allow(screen).to receive(:from_readline).and_return(nil)

      expect(screen.size).to eq([51, 280])
      expect(screen).to_not have_received(:from_readline)
    end
  end

  context 'from io console' do
    it "doesn't calculate size if jruby " do
      screen = described_class.new({})
      allow(screen).to receive(:jruby?).and_return(true)
      expect(screen.from_io_console).to eq(false)
    end

    it "calcualtes the size" do
      screen = described_class.new({}, output: output)
      allow(screen).to receive(:jruby?).and_return(false)
      allow(screen).to receive(:require).with('io/console').
        and_return(true)
      allow(output).to receive(:tty?).and_return(true)
      allow(IO).to receive(:method_defined?).with(:winsize).and_return(true)
      allow(output).to receive(:winsize).and_return([100, 200])

      expect(screen.from_io_console).to eq([100, 200])
      expect(output).to have_received(:winsize)
    end

    it "doesn't calculate size if io/console not available" do
      screen = described_class.new({})
      allow(screen).to receive(:jruby?).and_return(false)
      allow(screen).to receive(:require).with('io/console').
        and_raise(LoadError)
      expect(screen.from_io_console).to eq(false)
    end

    it "doesn't calculate size if it is run without a console" do
      screen = described_class.new({}, output: output)
      allow(screen).to receive(:jruby?).and_return(false)
      allow(screen).to receive(:require).with('io/console').
        and_return(true)
      allow(output).to receive(:tty?).and_return(true)
      allow(IO).to receive(:method_defined?).with(:winsize).and_return(false)
      expect(screen.from_io_console).to eq(false)
    end
  end

  context 'from tput' do
    it "doesn't run command if outside of terminal" do
      screen = described_class.new({}, output: output)
      allow(output).to receive(:tty?).and_return(false)
      expect(screen.from_tput).to eq(nil)
    end

    it "runs tput commands" do
      screen = described_class.new({}, output: output)
      allow(output).to receive(:tty?).and_return(true)
      allow(screen).to receive(:run_command).with('tput', 'lines').and_return(51)
      allow(screen).to receive(:run_command).with('tput', 'cols').and_return(280)
      expect(screen.from_tput).to eq([51, 280])
    end

    it "doesn't return zero size" do
      screen = described_class.new({}, output: output)
      allow(output).to receive(:tty?).and_return(true)
      allow(screen).to receive(:run_command).with('tput', 'lines').and_return(0)
      allow(screen).to receive(:run_command).with('tput', 'cols').and_return(0)
      expect(screen.from_tput).to eq(nil)
    end
  end

  context 'from stty' do
    it "doesn't run command if outside of terminal" do
      screen = described_class.new({}, output: output)
      allow(output).to receive(:tty?).and_return(false)
      expect(screen.from_stty).to eq(nil)
    end

    it "runs stty commands" do
      screen = described_class.new({}, output: output)
      allow(output).to receive(:tty?).and_return(true)
      allow(screen).to receive(:run_command).with('stty', 'size').and_return("51 280")
      expect(screen.from_stty).to eq([51, 280])
    end

    it "doesn't return zero size" do
      screen = described_class.new({}, output: output)
      allow(output).to receive(:tty?).and_return(true)
      allow(screen).to receive(:run_command).with('stty', 'size').and_return("0 0")
      expect(screen.from_stty).to eq(nil)
    end
  end

  context 'from env' do
    it "doesn't calculate size without COLUMNS key" do
      screen = described_class.new({'COLUMNS' => nil})
      expect(screen.from_env).to eq(nil)
    end

    it "extracts lines and columns from environment" do
      screen = described_class.new({'COLUMNS' => '280', 'LINES' => '51'})
      expect(screen.from_env).to eq([51, 280])
    end

    it "doesn't return zero size" do
      screen = described_class.new({'COLUMNS' => '0', 'LINES' => '0'})
      expect(screen.from_env).to eq(nil)
    end
  end

  context 'from ansicon' do
    it "doesn't calculate size without ANSICON key" do
      screen = described_class.new({'ANSICON' => nil})
      expect(screen.from_ansicon).to eq(nil)
    end

    it "extracts lines and columns from environment" do
      screen = described_class.new({'ANSICON' => '(280x51)'})
      expect(screen.from_ansicon).to eq([51, 280])
    end

    it "doesn't return zero size" do
      screen = described_class.new({'ANSICON' => '(0x0)'})
      expect(screen.from_ansicon).to eq(nil)
    end
  end

  context 'default size' do
    it "suggests default terminal size" do
      screen = described_class.new({'LINES' => 0, 'COLUMNS' => 0})
      expect(screen.default_size).to eq([27, 80])
    end

    it "attempts to get default terminal size from environment" do
      screen = described_class.new({'LINES' => 52, 'COLUMNS' => 200})
      expect(screen.default_size).to eq([52, 200])
    end
  end
end
