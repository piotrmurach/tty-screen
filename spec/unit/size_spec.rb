# coding: utf-8

require 'spec_helper'

RSpec.describe TTY::Screen, '.size' do
  let(:output) { StringIO.new('', 'w+') }

  subject(:screen) { described_class.new(output: output) }

  context 'default size' do
    it "suggests default terminal size" do
      allow(ENV).to receive(:[]).with('LINES').and_return(0)
      allow(ENV).to receive(:[]).with('COLUMNS').and_return(0)
      expect(screen.default_size).to eq([27, 80])
    end

    it "attempts to get default terminal size from environment" do
      allow(ENV).to receive(:[]).with('LINES').and_return(52)
      allow(ENV).to receive(:[]).with('COLUMNS').and_return(200)
      expect(screen.default_size).to eq([52, 200])
    end
  end

  context 'size' do
    it "correctly falls through choices" do
      allow(screen).to receive(:from_io_console).and_return([51, 280])
      allow(screen).to receive(:from_readline).and_return(nil)
      expect(screen.size).to eq([51, 280])
      expect(screen).to_not have_received(:from_readline)
      expect(screen.width).to eq(280)
      expect(screen.height).to eq(51)
    end

    it "allows to call size as class instance" do
      screen = double(:screen, size: [51, 280])
      allow(TTY::Screen).to receive(:new).and_return(screen)
      expect(TTY::Screen.size).to eq([51, 280])
      expect(TTY::Screen.width).to eq(280)
      expect(TTY::Screen.height).to eq(51)
      expect(TTY::Screen).to have_received(:new).exactly(3).times
    end
  end

  context 'from io console' do
    it "doesn't calculate size if jruby " do
      allow(screen).to receive(:jruby?).and_return(true)
      expect(screen.from_io_console).to eq(nil)
    end

    it "doesn't calculate size if io/console not available" do
      allow(screen).to receive(:jruby?).and_return(false)
      allow(Kernel).to receive(:require).with('io/console').and_raise(LoadError)
      expect(screen.from_io_console).to eq(nil)
    end

    it "doesn't calculate size if it is run without a console" do
      allow(IO).to receive(:respond_to?).with(:console).and_return(false)
      expect(screen.from_io_console).to eq(nil)
    end
  end

  context 'from tput' do
    it "doesn't run command if outside of terminal" do
      allow(output).to receive(:tty?).and_return(false)
      expect(screen.from_tput).to eq(nil)
    end

    it "runs tput commands" do
      allow(output).to receive(:tty?).and_return(true)
      allow(screen).to receive(:run_command).with('tput', 'lines').and_return(51)
      allow(screen).to receive(:run_command).with('tput', 'cols').and_return(280)
      expect(screen.from_tput).to eq([51, 280])
    end

    it "doesn't return zero size" do
      allow(output).to receive(:tty?).and_return(true)
      allow(screen).to receive(:run_command).with('tput', 'lines').and_return(0)
      allow(screen).to receive(:run_command).with('tput', 'cols').and_return(0)
      expect(screen.from_tput).to eq(nil)
    end
  end

  context 'from stty' do
    it "doesn't run command if outside of terminal" do
      allow(output).to receive(:tty?).and_return(false)
      expect(screen.from_stty).to eq(nil)
    end

    it "runs stty commands" do
      allow(output).to receive(:tty?).and_return(true)
      allow(screen).to receive(:run_command).with('stty', 'size').and_return("51 280")
      expect(screen.from_stty).to eq([51, 280])
    end

    it "doesn't return zero size" do
      allow(output).to receive(:tty?).and_return(true)
      allow(screen).to receive(:run_command).with('stty', 'size').and_return("0 0")
      expect(screen.from_stty).to eq(nil)
    end
  end

  context 'from env' do
    it "doesn't calculate size without COLUMNS key" do
      allow(ENV).to receive(:[]).with('COLUMNS').and_return nil
      expect(screen.from_env).to eq(nil)
    end

    it "extracts lines and columns from environment" do
      allow(ENV).to receive(:[]).with('COLUMNS').and_return("280")
      allow(ENV).to receive(:[]).with('LINES').and_return("51")
      expect(screen.from_env).to eq([51, 280])
    end

    it "doesn't return zero size" do
      allow(ENV).to receive(:[]).with('COLUMNS').and_return("0")
      allow(ENV).to receive(:[]).with('LINES').and_return("0")
      expect(screen.from_env).to eq(nil)
    end
  end

  context 'from ansicon' do
    it "doesn't calculate size without ANSICON key" do
      allow(ENV).to receive(:[]).with('ANSICON').and_return nil
      expect(screen.from_ansicon).to eq(nil)
    end

    it "extracts lines and columns from environment" do
      allow(ENV).to receive(:[]).with('ANSICON').and_return("(280x51)")
      expect(screen.from_ansicon).to eq([51, 280])
    end

    it "doesn't return zero size" do
      allow(ENV).to receive(:[]).with('ANSICON').and_return("(0x0)")
      expect(screen.from_ansicon).to eq(nil)
    end
  end
end
