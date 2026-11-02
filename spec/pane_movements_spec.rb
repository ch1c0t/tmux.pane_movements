require_relative 'cli/helper'
require 'tmpdir'

RSpec.describe 'pane movement executables' do
  DIRECTIONS = {
    'to-left-pane' => ['C-w', 'h', 'M-h', '-L'],
    'to-lower-pane' => ['C-w', 'j', 'M-j', '-D'],
    'to-right-pane' => ['C-w', 'l', 'M-l', '-R'],
    'to-upper-pane' => ['C-w', 'k', 'M-k', '-U']
  }.freeze

  def invoke(executable, command:, pane_count:)
    Dir.mktmpdir do |directory|
      fake_bin = File.join(directory, 'bin')
      FileUtils.mkdir_p(fake_bin)
      log = File.join(directory, 'tmux.log')
      fake_tmux = File.join(fake_bin, 'tmux')

      File.write(fake_tmux, <<~SH)
        #!/bin/sh
        printf '%s' "$1" >> "$TMUX_TEST_LOG"
        shift
        for argument do
          printf '\t%s' "$argument" >> "$TMUX_TEST_LOG"
        done
        printf '\n' >> "$TMUX_TEST_LOG"

        if [ "$1" = "-p" ]; then
          case "$*" in
            *'#{pane_id}'*)
              printf '%s\n' "$TMUX_TEST_PANE_ID"
              ;;
            *)
              printf '%s\t%s\n' "$TMUX_TEST_COMMAND" "$TMUX_TEST_PANE_COUNT"
              ;;
          esac
        fi
      SH
      File.chmod(0o755, fake_tmux)

      environment = {
        'PATH' => "#{fake_bin}:#{ENV.fetch('PATH', '')}",
        'TMUX_PANE' => '%42',
        'TMUX_TEST_LOG' => log,
        'TMUX_TEST_PANE_ID' => '%42',
        'TMUX_TEST_COMMAND' => command,
        'TMUX_TEST_PANE_COUNT' => pane_count.to_s
      }

      _stdout, stderr, status = Open3.capture3(environment, "./bin/#{executable}")
      expect(status.exitstatus).to eq(0), stderr

      File.readlines(log, chomp: true).map { |line| line.split("\t") }
    end
  end

  DIRECTIONS.each do |executable, (ctrl_w, vim_key, alt_key, tmux_direction)|
    context executable do
      it 'sends Ctrl-W navigation only to Vim and Neovim in a single-pane window' do
        %w[vim nvim].each do |application|
          commands = invoke(executable, command: application, pane_count: 1)
          expect(commands.last).to eq(['send-keys', '-t', '%42', ctrl_w, vim_key])
        end
      end

      it 'forwards the matching Alt chord to other applications in a single-pane window' do
        commands = invoke(executable, command: 'zsh', pane_count: 1)
        expect(commands.last).to eq(['send-keys', '-t', '%42', alt_key])
      end

      it 'continues to select the tmux pane when the window has multiple panes' do
        commands = invoke(executable, command: 'nvim', pane_count: 2)
        expect(commands.last).to eq(['select-pane', '-t', '%42', tmux_direction])
      end
    end
  end
end
