{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShellNoCC {
  packages = with pkgs; [

    # Terminal session
    zsh

    # Text Editors
    vim
    neovim
    
    # Version control
    git

    # Terminal Utils
    tmux

    # Basic terminal utils
    htop
    fd
    curl
    unzip
  ];
}
