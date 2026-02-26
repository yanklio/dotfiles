{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;

    # Prefix key
    prefix = "C-a";

    # Enable mouse
    mouse = true;

    extraConfig = ''
      # Custom split commands
      bind | split-window -h
      bind - split-window -v
      unbind '"'
      unbind %

      # Easy config reload
      bind r source-file ~/.config/tmux/tmux.conf

      # Easier pane navigation
      bind -n M-Left  select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up    select-pane -U
      bind -n M-Down  select-pane -D

      bind -n M-h select-pane -L
      bind -n M-l select-pane -R
      bind -n M-k select-pane -U
      bind -n M-j select-pane -D
    '';
  };
}
