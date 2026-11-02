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
