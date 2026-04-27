{ pkgs, ... }:

{
  home.packages = [ pkgs.fastfetch ];

  xdg.configFile."fastfetch/config.jsonc".text = builtins.toJSON {
    logo = {
      type = "small";
    };
    modules = [
      "title"
      "os"
      "kernel"
      "cpu"
      "gpu"
      "memory"
      "terminal"
      "shell"
      "packages"
      "uptime"
    ];
  };
}
