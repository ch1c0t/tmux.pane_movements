# tmux.pane_movements

This shard provides four executables for directional pane navigation:

- `to-left-pane`
- `to-lower-pane`
- `to-right-pane`
- `to-upper-pane`

Build them with:

```sh
bundle exec rake
```

Bind them to Alt+H/J/K/L in tmux:

```tmux
bind -n M-h run-shell "to-left-pane"
bind -n M-j run-shell "to-lower-pane"
bind -n M-k run-shell "to-upper-pane"
bind -n M-l run-shell "to-right-pane"
```

When the target window has more than one pane, an executable selects the
adjacent tmux pane. When it has only one pane, it sends `C-w` followed by
`h`, `j`, `k`, or `l` only when the foreground command is `vim` or
`nvim`. For every other application, it forwards the matching Alt chord
(`M-h`, `M-j`, `M-k`, or `M-l`) into the pane.

The target pane comes from `TMUX_PANE`; when that variable is unavailable,
the executable asks tmux for its current pane. Pane metadata and key commands
are explicitly targeted at that pane, so the pane count is scoped to its
window rather than relying on tmux's implicit default target.

When the foreground command is `tmux.repl.input`, the lower and upper bindings
forward Alt+J/K to the input process even in a multi-pane window. This lets the
REPL use those keys as input-selection aliases without breaking pane movement
for other applications.
