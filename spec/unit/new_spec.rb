# encoding: utf-8

require 'spec_helper'

RSpec.describe TTY::Screen, '.new' do
  let(:output) { StringIO.new('', 'w+') }

  it "initializes size and color detection" do
    allow(TTY::Screen::Color).to receive(:new).with(output: output, verbose: false)
    allow(TTY::Screen::Size).to receive(:new).with(output: output, verbose: false)

    TTY::Screen.new(output: output)

    expect(TTY::Screen::Color).to have_received(:new).with(output: output, verbose: false)
    expect(TTY::Screen::Size).to have_received(:new).with(output: output, verbose: false)
  end

  it "delegates size call" do
    size_instance = spy(:size)
    allow(TTY::Screen::Size).to receive(:new).and_return(size_instance)

    screen = described_class.new
    screen.size

    expect(size_instance).to have_received(:size)
  end

  it "allows to call size as class instance" do
    size_instance = double(:size, size: [51, 280])
    allow(TTY::Screen::Size).to receive(:new).and_return(size_instance)

    expect(TTY::Screen.size).to eq([51, 280])
    expect(TTY::Screen.width).to eq(280)
    expect(TTY::Screen.height).to eq(51)
    expect(TTY::Screen::Size).to have_received(:new).exactly(3).times
  end

  it "delegates color call" do
    color_instance = spy(:color)
    allow(TTY::Screen::Color).to receive(:new).and_return(color_instance)

    screen = described_class.new
    screen.color?

    expect(color_instance).to have_received(:supports?)
  end

  it "allows to call color as class instance" do
    color_instance = double(:size, supports?: false)
    allow(TTY::Screen::Color).to receive(:new).and_return(color_instance)

    expect(TTY::Screen.color?).to eq(false)
    expect(TTY::Screen::Color).to have_received(:new).exactly(1).times
  end
end
