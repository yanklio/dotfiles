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

    # API tools
    bruno-cli

    # Programming tools
    nodejs
    jdk17_headless
    jdt-language-server
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

  systemd.user.services.podman = {
    Unit = {
      Description = "Podman API Service";
    };
    Service = {
      ExecStart = "${pkgs.podman}/bin/podman system service --time=0";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  fonts.fontconfig.enable = true;

  programs.home-manager.enable = true;
}
