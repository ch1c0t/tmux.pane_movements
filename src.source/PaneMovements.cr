MOVEMENTS = {
  :left  => {tmux: "-L", vim: "h", alt: "M-h"},
  :lower => {tmux: "-D", vim: "j", alt: "M-j"},
  :right => {tmux: "-R", vim: "l", alt: "M-l"},
  :upper => {tmux: "-U", vim: "k", alt: "M-k"},
}

def self.run(direction : Symbol) : Nil
  movement = movement_for(direction)
  pane_id = target_pane_id
  application, pane_count = pane_details(pane_id)

  if pane_count == 1
    move_in_application(pane_id, application, movement)
  else
    move_to_tmux_pane(pane_id, movement.tmux)
  end
end

private def self.movement_for(direction : Symbol)
  MOVEMENTS[direction]? || raise ArgumentError.new("Unknown pane movement direction: #{direction}")
end

private def self.pane_details(pane_id : String) : Tuple(String, Int32)
  fields = tmux([
    "display-message",
    "-p",
    "-t", pane_id,
    "\#{pane_current_command}\t\#{window_panes}"
  ]).strip.split('\t', 2)

  unless fields.size == 2
    raise "Unexpected tmux pane metadata: #{fields.inspect}"
  end

  pane_count = fields[1].to_i?
  raise "Invalid pane count in tmux metadata: #{fields[1].inspect}" unless pane_count

  {File.basename(fields[0]), pane_count}
end

private def self.move_to_tmux_pane(pane_id : String, direction : String) : Nil
  tmux(["select-pane", "-t", pane_id, direction])
end

private def self.move_in_application(pane_id : String, application : String, movement) : Nil
  keys = if vim_or_neovim?(application)
    ["C-w", movement.vim]
  else
    [movement.alt]
  end

  tmux(["send-keys", "-t", pane_id] + keys)
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
