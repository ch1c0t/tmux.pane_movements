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
