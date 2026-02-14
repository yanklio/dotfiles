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
      ls = "ls --color=auto -hv";
      grep = "grep --color=auto";
      diff = "diff --color=auto";
      ip = "ip -c=auto";
      l = "ls";
      ll = "ls -l";
      la = "ls -lA";
      mv = "mv -i";
    };

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ]; 
      theme = "simple";
    };

    initContent = ''
      # Key Bindings (Vim + Search)
      bindkey "\e[A" history-beginning-search-backward
      bindkey "\e[B" history-beginning-search-forward
      
      # Enable Vim mode
      bindkey -v

      # Terminal Appearance: Set title to current path
      precmd () { print -Pn "\e]2;%-3~\a"; }

      # Show logo on startup (only for top-level shells)
      if [[ $SHLVL -le 1 ]]; then
        fastfetch -c ~/.fastfetch-config.jsonc
      fi

      # Add local bin to path
      export PATH="$HOME/.local/bin:$PATH"
    '';
  };
}
  
