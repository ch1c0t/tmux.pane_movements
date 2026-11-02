require_relative 'helper'

describe 'something with RSpec' do
  it 'allows to test Crystal code with Ruby' do
    expect(true).to be true
    expect(false).to be false
  end
end

describe 'cli' do
  it 'prints a help message' do
    stdout = cli '--help'
    expect(stdout.first).to start_with 'tmux.pane_movements provides'
  end
end
