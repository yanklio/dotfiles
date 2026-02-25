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
    in
    {
      homeConfigurations."yanklio" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        modules = [
          # Agenix module setup
          agenix.homeManagerModules.default
          {
            age.secrets.wakatime_api = {
              file = /home/yanklio/.config/agenix/wakatime_api.age;
            };
            age.identityPaths = [ /home/yanklio/.ssh/id_ed25519 ];
          }
          # Load the main home configuration
          ./home.nix
        ];
        extraSpecialArgs = { inherit inputs; };
      };
    };
}
