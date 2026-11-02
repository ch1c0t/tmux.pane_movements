module PaneMovements
  def self.run(direction : Symbol) : Nil
    tmux_direction, vim_direction, alt_key = case direction
    when :left
      {"-L", "h", "M-h"}
    when :lower
      {"-D", "j", "M-j"}
    when :right
      {"-R", "l", "M-l"}
    when :upper
      {"-U", "k", "M-k"}
    else
      raise ArgumentError.new("Unknown pane movement direction: #{direction}")
    end

    pane_id = target_pane_id
    metadata = tmux([
      "display-message",
      "-p",
      "-t", pane_id,
      "\#{pane_current_command}\t\#{window_panes}"
    ]).strip

    fields = metadata.split('\t', 2)
    unless fields.size == 2
      raise "Unexpected tmux pane metadata: #{metadata.inspect}"
    end

    current_command = File.basename(fields[0])
    pane_count = fields[1].to_i

    if pane_count == 1
      keys = vim_or_neovim?(current_command) ? ["C-w", vim_direction] : [alt_key]
      tmux(["send-keys", "-t", pane_id] + keys)
    else
      tmux(["select-pane", "-t", pane_id, tmux_direction])
    end
  end

  private def self.target_pane_id : String
    if pane_id = ENV["TMUX_PANE"]?
      return pane_id unless pane_id.empty?
    end

    pane_id = tmux(["display-message", "-p", "\#{pane_id}"]).strip
    raise "tmux did not return a target pane ID" if pane_id.empty?
    pane_id
  end

  private def self.vim_or_neovim?(command : String) : Bool
    command == "vim" || command == "nvim"
  end

  private def self.tmux(arguments : Array(String)) : String
    output = IO::Memory.new
    error = IO::Memory.new
    status = Process.run("tmux", arguments, output: output, error: error)

    return output.to_s if status.success?

    detail = error.to_s.strip
    detail = "tmux exited unsuccessfully" if detail.empty?
    raise "tmux #{arguments.first} failed: #{detail}"
  end
end
