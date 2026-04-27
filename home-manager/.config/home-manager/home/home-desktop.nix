{ config, pkgs, inputs, ... }:

{
  imports = [
    ../modules/alacritty.nix
    ../modules/zed.nix
  ];

  # Desktop-specific packages can be added here
  home.packages = with pkgs; [
    # Add GUI/desktop-only packages here
  ];
}
