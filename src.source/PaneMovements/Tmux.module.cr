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
