{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;

    initLua = ''
      -- Base options
      vim.opt.expandtab = true
      vim.opt.tabstop = 2
      vim.opt.softtabstop = 2
      vim.opt.shiftwidth = 2
      vim.opt.number = true
      vim.opt.relativenumber = true
      vim.opt.termguicolors = true
      vim.opt.cursorline = true
      vim.opt.smartindent = true
      vim.opt.wrap = false
      vim.opt.clipboard = 'unnamedplus'
      vim.g.mapleader = " "
      vim.g.maplocalleader = "\\"

      -- Load friendly-snippets
      require('luasnip.loaders.from_vscode').lazy_load()

      -- Theme
      vim.opt.background = 'dark'
      require('gruvbox').setup({
        contrast = 'hard',
        transparent_mode = true,
      })
      vim.cmd('colorscheme gruvbox')

      -- Treesitter (nvim-treesitter 0.10+ — highlight/indent are native nvim features now)
      vim.api.nvim_create_autocmd('FileType', {
        callback = function()
          local ok = pcall(vim.treesitter.start)
          if not ok then
            vim.bo.syntax = 'on'
          end
        end,
      })

      -- Telescope
      local telescope = require('telescope')
      telescope.setup({
        defaults = {
          mappings = {
            i = {
              ['<C-j>'] = 'move_selection_next',
              ['<C-k>'] = 'move_selection_previous',
            },
          },
        },
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
        },
      })
      telescope.load_extension('ui-select')

      -- Keymaps for Telescope
      vim.keymap.set('n', '<leader>ff', '<cmd>Telescope find_files<cr>')
      vim.keymap.set('n', '<leader>fg', '<cmd>Telescope live_grep<cr>')
      vim.keymap.set('n', '<leader>fb', '<cmd>Telescope buffers<cr>')
      vim.keymap.set('n', '<leader>fh', '<cmd>Telescope help_tags<cr>')

      -- LSP (nvim 0.11+ native API, servers provided by Nix)
      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      vim.lsp.config('lua_ls', { capabilities = capabilities })
      vim.lsp.config('ts_ls', { capabilities = capabilities })
      vim.lsp.config('html', { capabilities = capabilities })
      vim.lsp.config('cssls', { capabilities = capabilities })

      vim.lsp.enable({ 'lua_ls', 'ts_ls', 'html', 'cssls' })

      -- LSP keymaps
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition)
      vim.keymap.set('n', 'K', vim.lsp.buf.hover)
      vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename)
      vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action)
      vim.keymap.set('n', 'gr', vim.lsp.buf.references)

      -- Completion
      local cmp = require('cmp')
      local luasnip = require('luasnip')
      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { 'i', 's' }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's' }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
        }, {
          { name = 'buffer' },
        }),
      })

      -- File explorer (Neo-tree)
      require('neo-tree').setup({
        filesystem = {
          filtered_items = {
            visible = true,
          },
        },
      })
      vim.keymap.set('n', '<leader>e', '<cmd>Neotree toggle<cr>')

      -- Status line
      require('lualine').setup({
        options = {
          theme = 'gruvbox',
          transparent = true,
        },
      })

      -- Dashboard
      local alpha = require('alpha')
      local dashboard = require('alpha.themes.dashboard')
      dashboard.section.header.val = {
        '  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ',
        '  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ',
        '  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ',
        '  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ',
        '  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ',
        '  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ',
      }
      dashboard.section.buttons.val = {
        dashboard.button('f', ' Find file', '<cmd>Telescope find_files<cr>'),
        dashboard.button('e', ' New file', '<cmd>ene <BAR> startinsert <cr>'),
        dashboard.button('r', ' Recent files', '<cmd>Telescope oldfiles<cr>'),
        dashboard.button('g', ' Find text', '<cmd>Telescope live_grep<cr>'),
        dashboard.button('q', ' Quit', '<cmd>qa<cr>'),
      }
      alpha.setup(dashboard.opts)

      -- Copilot
      require('copilot').setup({
        suggestion = {
          auto_trigger = true,
          keymap = {
            accept  = '<M-l>',
            next    = '<M-]>',
            prev    = '<M-[>',
            dismiss = '<M-e>',
          },
        },
      })

      -- Debugging
      local dap = require('dap')
      local dapui = require('dapui')
      require('dap-go').setup()
      dapui.setup()

      dap.listeners.after.event_initialized['dapui_config'] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated['dapui_config'] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited['dapui_config'] = function()
        dapui.close()
      end

      vim.keymap.set('n', '<F5>',  dap.continue)
      vim.keymap.set('n', '<F9>',  dap.toggle_breakpoint)
      vim.keymap.set('n', '<F10>', dap.step_over)
      vim.keymap.set('n', '<F11>', dap.step_into)

      -- Formatting (none-ls)
      local null_ls = require('null-ls')
      null_ls.setup({
        sources = {
          null_ls.builtins.formatting.stylua,
          null_ls.builtins.formatting.prettierd,
          null_ls.builtins.formatting.black,
          null_ls.builtins.formatting.isort,
        },
      })
      vim.keymap.set('n', '<leader>cf', vim.lsp.buf.format)

      -- Which-key
      require('which-key').setup()
    '';

    extraPackages = with pkgs; [
      # LSP servers (Nix-managed, no Mason downloads)
      nodePackages.vscode-langservers-extracted  # html, cssls
      nodePackages.typescript-language-server    # ts_ls
      lua-language-server                        # lua_ls
      gopls
      pyright
      nixd

      # Formatters
      stylua
      prettierd
      black
      isort
    ];

    plugins = with pkgs.vimPlugins; [
      # Theme
      gruvbox-nvim

      # Treesitter
      (nvim-treesitter.withPlugins (p: with p; [
        bash
        c
        cpp
        css
        html
        javascript
        json
        lua
        nix
        python
        typescript
        vim
        vimdoc
        yaml
      ]))

      # Telescope
      telescope-nvim
      telescope-ui-select-nvim
      plenary-nvim

      # LSP
      nvim-lspconfig

      # Completions
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      luasnip
      cmp_luasnip
      friendly-snippets

      # File explorer
      neo-tree-nvim
      nui-nvim
      nvim-web-devicons

      # Status line
      lualine-nvim

      # Dashboard
      alpha-nvim

      # Copilot
      copilot-lua

      # Debugging
      nvim-dap
      nvim-dap-ui
      nvim-dap-go
      nvim-nio

      # Formatting/Linting
      none-ls-nvim

      # Utils
      which-key-nvim
    ];
  };

  home.packages = with pkgs; [
    # Formatters available globally (also in extraPackages for nvim)
    stylua
    prettierd
    black
    isort
  ];
}
