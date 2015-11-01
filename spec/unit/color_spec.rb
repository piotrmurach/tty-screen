# encoding: utf-8

require 'spec_helper'

RSpec.describe TTY::Screen::Color, '.supports?' do
  let(:output) { StringIO.new('', 'w+') }

  subject(:color) { described_class.new(output: output) }

  it "doesn't check color support for non tty terminal" do
    allow(output).to receive(:tty?).and_return(false)

    expect(color.supports?).to eq(false)
  end

  it "fails to load curses for color support" do
    allow(color).to receive(:require).with('curses').
      and_raise(LoadError)

    expect(color.from_curses).to eq(described_class::NoValue)
  end

  it "loads curses for color support" do
    allow(color).to receive(:require).with('curses').and_return(true)
    stub_const("Curses", Object.new)
    curses = double(:curses)
    allow(curses).to receive(:init_screen)
    allow(curses).to receive(:has_colors?).and_return(true)
    allow(curses).to receive(:close_screen)

    expect(color.from_curses(curses)).to eql(true)
    expect(curses).to have_received(:has_colors?)
  end

  it "fails to find color for dumb terminal" do
    allow(ENV).to receive(:[]).with('TERM').and_return('dumb')

    expect(color.from_term).to eq(false)
  end

  it "inspects term variable for color capabilities" do
    allow(ENV).to receive(:[]).with('TERM').and_return('xterm')

    expect(color.from_term).to eq(true)
  end

  it "inspects color terminal variable for support" do
    allow(ENV).to receive(:include?).with('COLORTERM').and_return(true)

    expect(color.from_env).to eq(true)
  end
end
