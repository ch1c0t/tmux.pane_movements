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
