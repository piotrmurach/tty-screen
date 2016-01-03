# encoding: utf-8

RSpec.describe TTY::Screen, '.new' do

  it "initializses size with defaults" do
    allow(TTY::Screen::Size).to receive(:new)
    TTY::Screen.new
    expect(TTY::Screen::Size).to have_received(:new).
      with(ENV, {output: $stderr, verbose: false})
  end

  it "initializes size with values" do
    allow(TTY::Screen::Size).to receive(:new)

    TTY::Screen.new(output: :output, verbose: true)

    expect(TTY::Screen::Size).to have_received(:new).
      with(ENV, output: :output, verbose: true)
  end

  it "delegates size call" do
    size_instance = spy(:size)
    allow(TTY::Screen::Size).to receive(:new).and_return(size_instance)

    screen = described_class.new
    screen.size

    expect(size_instance).to have_received(:size)
  end

  it "calls size" do
    size_instance = double(:size, size: [51, 280])
    allow(TTY::Screen::Size).to receive(:new).and_return(size_instance)

    expect(TTY::Screen.size).to eq([51, 280])
    expect(TTY::Screen::Size).to have_received(:new).once
  end

  it "calls width" do
    size_instance = double(:size, size: [51, 280])
    allow(TTY::Screen::Size).to receive(:new).and_return(size_instance)

    expect(TTY::Screen.width).to eq(280)
    expect(TTY::Screen::Size).to have_received(:new).once
  end

  it "calls height" do
    size_instance = double(:size, size: [51, 280])
    allow(TTY::Screen::Size).to receive(:new).and_return(size_instance)
    expect(TTY::Screen.height).to eq(51)
  end
end
