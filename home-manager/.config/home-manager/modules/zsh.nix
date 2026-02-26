{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 100000;
      save = 100000;
      path = "$HOME/.history";
      ignoreDups = true;
      share = true;
    };

    shellAliases = {
      v = "nvim";
      o = "xdg-open";
      g = "git";
      ls = "eza";
      grep = "grep --color=auto";
      diff = "diff --color=auto";
      ip = "ip -c=auto";
      l = "ls";
      ll = "eza -l";
      la = "eza -lA";
      mv = "mv -i";
    };

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
      theme = "simple";
    };

    initContent = ''
      # Enable Vim mode first, then re-apply custom bindings on top
      bindkey -v
      bindkey "\e[A" history-beginning-search-backward
      bindkey "\e[B" history-beginning-search-forward

      # Terminal Appearance: Set title to current path
      _set_terminal_title() { print -Pn "\e]2;%-3~\a" }
      precmd_functions+=(_set_terminal_title)

      # Show logo on startup (only for top-level shells)
      if [[ $SHLVL -le 1 ]]; then
        fastfetch
      fi

      # Add local bin to path
      export PATH="$HOME/.local/bin:$PATH"
    '';
  };
}
