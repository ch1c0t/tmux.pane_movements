def self.forward_to_repl_input?(application : String, direction : Symbol) : Bool
  application == "tmux.repl.input" && (direction == :lower || direction == :upper)
end

def self.keys_for(application : String, movement : Movement::Definition) : Array(String)
  if vim_or_neovim?(application)
    ["C-w", movement[:vim_key]]
  else
    [movement[:alt_key]]
  end
end

private def self.vim_or_neovim?(application : String) : Bool
  application == "vim" || application == "nvim"
end
