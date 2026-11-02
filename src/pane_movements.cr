module PaneMovements
  def self.run(direction : Symbol) : Nil
    movement = Movement.resolve(direction)
    pane_id = Tmux.target_pane_id
    pane = Tmux.pane_details(pane_id)

    if pane.pane_count == 1
      Tmux.send_keys(pane_id, Application.keys_for(pane.application, movement))
    else
      Tmux.select_pane(pane_id, movement.tmux)
    end
  end

  module Movement
    alias Definition = NamedTuple(tmux: String, vim_key: String, alt_key: String)

    MOVEMENTS = {
      :left  => {tmux: "-L", vim_key: "h", alt_key: "M-h"},
      :lower => {tmux: "-D", vim_key: "j", alt_key: "M-j"},
      :right => {tmux: "-R", vim_key: "l", alt_key: "M-l"},
      :upper => {tmux: "-U", vim_key: "k", alt_key: "M-k"},
    }

    def self.resolve(direction : Symbol) : Definition
      MOVEMENTS[direction]? || raise ArgumentError.new("Unknown pane movement direction: #{direction}")
    end
  end

  module Application
    def self.keys_for(application : String, movement : Movement::Definition) : Array(String)
      if vim_or_neovim?(application)
        ["C-w", movement.vim_key]
      else
        [movement.alt_key]
      end
    end

    private def self.vim_or_neovim?(application : String) : Bool
      application == "vim" || application == "nvim"
    end
  end

  module Tmux
    def self.target_pane_id : String
      if pane_id = ENV["TMUX_PANE"]?
        return pane_id unless pane_id.empty?
      end

      pane_id = execute(["display-message", "-p", "\#{pane_id}"]).strip
      raise "tmux did not return a target pane ID" if pane_id.empty?
      pane_id
    end

    def self.pane_details(pane_id : String) : NamedTuple(application: String, pane_count: Int32)
      metadata = execute([
        "display-message",
        "-p",
        "-t", pane_id,
        "\#{pane_current_command}\t\#{window_panes}"
      ]).strip

      fields = metadata.split('\t', 2)
      unless fields.size == 2
        raise "Unexpected tmux pane metadata: #{metadata.inspect}"
      end

      pane_count = fields[1].to_i?
      raise "Invalid pane count in tmux metadata: #{fields[1].inspect}" unless pane_count

      {
        application: File.basename(fields[0]),
        pane_count: pane_count,
      }
    end

    def self.select_pane(pane_id : String, direction : String) : Nil
      execute(["select-pane", "-t", pane_id, direction])
      nil
    end

    def self.send_keys(pane_id : String, keys : Array(String)) : Nil
      execute(["send-keys", "-t", pane_id] + keys)
      nil
    end

    private def self.execute(arguments : Array(String)) : String
      output = IO::Memory.new
      error = IO::Memory.new
      status = Process.run("tmux", arguments, output: output, error: error)

      return output.to_s if status.success?

      detail = error.to_s.strip
      detail = "tmux exited unsuccessfully" if detail.empty?
      raise "tmux #{arguments.first} failed: #{detail}"
    end
  end
end
