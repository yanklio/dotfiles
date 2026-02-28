{
  description = "Home Manager configuration of yanklio";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{
      nixpkgs,
      home-manager,
      agenix,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = nixpkgs.lib;

      # Infer username from the environment; fall back to "yanklio".
      # On a fresh machine run: USER=yourname home-manager switch --flake ...
      username = let u = builtins.getEnv "USER"; in if u != "" then u else "yanklio";
      homeDir  = "/home/${username}";

      hasWakatimeSecret = builtins.pathExists ./secrets/wakatime_api.age;

      # Shared agenix module used by both profiles.
      # The wakatime secret is only wired up when the .age file is present —
      # safe to apply on a fresh machine where secrets haven't been copied over yet.
      agenixModule = [
        agenix.homeManagerModules.default
        {
          age.identityPaths = [ "${homeDir}/.ssh/id_ed25519" ];
          age.secrets = lib.mkIf hasWakatimeSecret {
            wakatime_api.file = ./secrets/wakatime_api.age;
          };
        }
      ];
    in
    {
      # Shell-only profile: terminal tools, no GUI apps
      # Usage: home-manager switch --flake .#yanklio-shell
      homeConfigurations."yanklio-shell" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = agenixModule ++ [ ./home/home-shell.nix ];
        extraSpecialArgs = { inherit inputs username homeDir; };
      };

      # Desktop profile: shell + GUI apps (alacritty, zed), composed at flake level
      # Usage: home-manager switch --flake .#yanklio-desktop
      homeConfigurations."yanklio-desktop" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = agenixModule ++ [ ./home/home-shell.nix ./home/home-desktop.nix ];
        extraSpecialArgs = { inherit inputs username homeDir; };
      };
    };
}
