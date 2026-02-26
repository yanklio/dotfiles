{ config, pkgs, inputs,  ... }:

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
     ./modules/zed.nix
  ];

  home.packages = with pkgs; [
    inputs.agenix.packages.${pkgs.system}.agenix

    # Basic utils
    htop
    curl
    stow
    fastfetch

    # Handy tools
    bat
    eza
    fzf

    # Relax
    cava

    # TUIs
    lazygit
    lazydocker
    pgcli

    # Programming tools
    nodejs
    jdk17_headless
    go
    conda

    # AI Tools
    opencode

    # Fonts
    nerd-fonts.jetbrains-mono
    noto-fonts
  ];

  # Git config
  programs.git = {
     enable = true;
     settings.user = {
         name = "Yaroslav Ustinov";
         email = "y.ustinov2004@gmail.com";
     };
  };

  programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = [ "--cmd cd" ];
  };


  services = {
      ollama = {
        enable = true;
      };
      podman = {
        enable = true;
      };
  };


  home.sessionVariables = {
    EDITOR = "nvim";
  };

  fonts.fontconfig.enable = true;

  programs.home-manager.enable = true;
}
