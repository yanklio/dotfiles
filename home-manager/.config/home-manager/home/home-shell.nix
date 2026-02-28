{ config, pkgs, inputs, username, homeDir, ... }:

{
  home.username = username;
  home.homeDirectory = homeDir;
  home.stateVersion = "25.11";

  imports = [
    ../modules/zsh.nix
    ../modules/vim.nix
    ../modules/neovim.nix
    ../modules/tmux.nix
    ../modules/fastfetch.nix
  ];

  home.packages = with pkgs; [
    inputs.agenix.packages.${pkgs.system}.agenix

    # Basic utils
    htop
    curl
    stow

    # Handy tools
    bat
    eza
    fzf
    ripgrep
    fd
    btop

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
    gcc
    nixd
    nil

    # AI Tools
    opencode

    # Fonts
    nerd-fonts.blex-mono
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
