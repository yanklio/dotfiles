{ config, pkgs, ... }:

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
      ui_font_weight = 400;
      ui_font_size = 15;
      ui_font_family = "Noto Sans";
      buffer_font_size = 15;
      buffer_font_family = "JetBrains Mono";
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
            api-key = "$WAKATIME_API_KEY"; 
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
}
