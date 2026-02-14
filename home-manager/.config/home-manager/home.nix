{ config, pkgs, ... }:

let
  # Define the custom shell script here
  opencode = pkgs.writeShellApplication {
    name = "opencode";
    
    # This ensures nodejs is in the path when the script runs
    runtimeInputs = [ pkgs.nodejs ];

    text = ''
      exec npx opencode-ai@latest "$@"
    '';
  };
in
{
  home.username = "yanklio";
  home.homeDirectory = "/home/yanklio";
  home.stateVersion = "25.11"; 

  imports = [
     ./modules/zsh.nix
     ./modules/alacritty.nix
     ./modules/vim.nix
     ./modules/neovim.nix
     ./modules/tmux.nix
  ];

  home.packages = with pkgs; [
    # Shell
    zsh
  
    # Terminal utils
    tmux

    # Basic utils
    git

    # Handy tools
    fastfetch
    htop
    fzf
    curl
    stow

    # Programming tools
    nodejs
    opencode

    # Fonts
    nerd-fonts.jetbrains-mono
  ];

  home.file = {
  };

  # Git config
  programs.git = {
     enable = true;
     settings.user = {     
         name = "Yaroslav Ustinov";
         email = "y.ustinov2004@gmail.com";
     };
  };

  home.sessionVariables = {
    EDITOR = "vim";
  };

  fonts.fontconfig.enable = true;

  programs.home-manager.enable = true;
}
