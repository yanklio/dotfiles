{ config, lib, pkgs, ... }:

let
  hasWakatimeSecret = config.age.secrets ? wakatime_api;

  zedWakatimeScript = pkgs.writeText "zed-wakatime-api-key.py" ''
    import json
    import os

    settings_file = os.environ["SETTINGS_FILE"]
    secret_path = os.environ["SECRET_PATH"]
    xdg_runtime = os.environ.get("XDG_RUNTIME_DIR", "")
    secret_path = secret_path.replace("''${XDG_RUNTIME_DIR}", xdg_runtime)

    if not (os.path.isfile(secret_path) and os.path.isfile(settings_file)):
        raise SystemExit(0)

    with open(secret_path, "r", encoding="utf-8") as fh:
        api_key = fh.read().rstrip("\n")

    try:
        with open(settings_file, "r", encoding="utf-8") as fh:
            data = json.load(fh)
    except Exception:
        data = {}

    lsp = data.setdefault("lsp", {})
    wakatime = lsp.setdefault("wakatime", {})
    init_opts = wakatime.setdefault("initialization_options", {})
    init_opts["api-key"] = api_key

    with open(settings_file, "w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=2, sort_keys=False)
        fh.write("\n")
  '';
in
{
  programs.zed-editor = {
    enable = true;
    package = null;

    extensions = [
      "nix"
      "python"
      "ruff"
      "material-icon-theme"
      "astro"
    ];

    userSettings = {
      ui_font_weight = 500;
      ui_font_size = 15;
      ui_font_family = "Blex Nerd Font";
      buffer_font_size = 15;
      buffer_font_family = "Blex Nerd Font Mono";
      buffer_font_weight = 500;
      vim_mode = true;
      prettier = {
        allowed = true;
      };

      theme = {
        mode = "system";
        light = "Gruvbox Light";
        dark = "Gruvbox Dark";
      };

      icon_theme = {
        mode = "dark";
        light = "Material Icon Theme";
        dark = "Material Icon Theme";
      };

      project_panel = {
        auto_open = { on_paste = false; };
        hide_hidden = false;
        hide_root = false;
        indent_guides = { show = "always"; };
        indent_size = 24.0;
        git_status = true;
        folder_icons = false;
        file_icons = true;
        entry_spacing = "standard";
        default_width = 241.0;
        dock = "left";
      };

      agent = {
        message_editor_min_lines = 6;
        default_profile = "ask";
        default_model = {
          provider = "copilot_chat";
          model = "claude-sonnet-4.5";
        };
        always_allow_tool_actions = true;
      };

      experimental.theme_overrides = {
        "background.appearance" = "blurred";
      };

      languages = {
        Python = {
          language_servers = [ "ruff" "!pylsp" "!python-refactoring" "!basedpyright" "!pyright" ];
          format_on_save = "on";
          formatter = {
            language_server = { name = "ruff"; };
          };
          code_actions_on_format = {
            "source.organizeImports.ruff" = true;
            "source.fixAll.ruff" = true;
          };
        };
      };

      lsp = {
        wakatime = {
          initialization_options = {
            api-key = "";
          };
        };
        ruff = {
          initialization_options = {
            settings = {
              lineLength = 100;
              lint = {
                extendSelect = [ "I" ];
              };
            };
          };
        };
      };

      context_servers = {
        "Astro docs" = {
          enabled = true;
          command = "npx";
          args = [ "-y" "mcp-remote" "https://mcp.docs.astro.build/mcp" ];
        };
      };
    };
  };

  home.activation.zedWakatimeApiKey = lib.mkIf hasWakatimeSecret (
    lib.hm.dag.entryAfter [ "zedSettingsActivation" ] ''
      SETTINGS_FILE="${config.xdg.configHome}/zed/settings.json" \
        SECRET_PATH="${config.age.secrets.wakatime_api.path}" \
        ${pkgs.python3}/bin/python "${zedWakatimeScript}"
    ''
  );
}
