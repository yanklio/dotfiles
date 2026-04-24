vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

if vim.fn.has("vms") == 0 then
  vim.opt.undofile = true
end

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
vim.opt.clipboard = "unnamedplus"
vim.opt.background = "dark"

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  { "ellisonleao/gruvbox.nvim", lazy = false },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      vim.api.nvim_create_autocmd("FileType", {
        callback = function()
          local ok = pcall(vim.treesitter.start)
          if not ok then
            vim.bo.syntax = "on"
          end
        end,
      })
    end,
  },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-ui-select.nvim",
    },
  },
  { "neovim/nvim-lspconfig" },
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
    },
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
  },
  { "nvim-lualine/lualine.nvim" },
  { "goolord/alpha-nvim" },
  { "zbirenbaum/copilot.lua" },
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "leoluz/nvim-dap-go",
      "nvim-neotest/nvim-nio",
    },
  },
  { "nvimtools/none-ls.nvim" },
  {
    "folke/which-key.nvim",
    config = function()
      require("which-key").setup()
    end,
  },
})

require("luasnip.loaders.from_vscode").lazy_load()

require("gruvbox").setup({
  contrast = "hard",
  transparent_mode = true,
})
vim.cmd("colorscheme gruvbox")

local telescope = require("telescope")
telescope.setup({
  defaults = {
    mappings = {
      i = {
        ["<C-j>"] = "move_selection_next",
        ["<C-k>"] = "move_selection_previous",
      },
    },
  },
  extensions = {
    ["ui-select"] = {
      require("telescope.themes").get_dropdown(),
    },
  },
})
telescope.load_extension("ui-select")

vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>")
vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>")
vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>")
vim.keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<cr>")

local capabilities = require("cmp_nvim_lsp").default_capabilities()
local lsp_servers = {
  { name = "lua_ls", executable = "lua-language-server" },
  { name = "ts_ls", executable = "typescript-language-server" },
  { name = "html", executable = "vscode-html-language-server" },
  { name = "cssls", executable = "vscode-css-language-server" },
}

for _, server in ipairs(lsp_servers) do
  if vim.fn.executable(server.executable) == 1 then
    vim.lsp.config(server.name, { capabilities = capabilities })
    vim.lsp.enable(server.name)
  end
end

vim.keymap.set("n", "gd", vim.lsp.buf.definition)
vim.keymap.set("n", "K", vim.lsp.buf.hover)
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename)
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action)
vim.keymap.set("n", "gr", vim.lsp.buf.references)

local cmp = require("cmp")
local luasnip = require("luasnip")
cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.abort(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { "i", "s" }),
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "luasnip" },
  }, {
    { name = "buffer" },
  }),
})

require("neo-tree").setup({
  filesystem = {
    filtered_items = {
      visible = true,
    },
  },
})
vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<cr>")

require("lualine").setup({
  options = {
    theme = "gruvbox",
    transparent = true,
  },
})

local alpha = require("alpha")
local dashboard = require("alpha.themes.dashboard")
dashboard.section.header.val = {
  "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
  "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
  "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
  "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
  "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
  "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
}
dashboard.section.buttons.val = {
  dashboard.button("f", " Find file", "<cmd>Telescope find_files<cr>"),
  dashboard.button("e", " New file", "<cmd>ene <BAR> startinsert <cr>"),
  dashboard.button("r", " Recent files", "<cmd>Telescope oldfiles<cr>"),
  dashboard.button("g", " Find text", "<cmd>Telescope live_grep<cr>"),
  dashboard.button("q", " Quit", "<cmd>qa<cr>"),
}
alpha.setup(dashboard.opts)

require("copilot").setup({
  suggestion = {
    auto_trigger = true,
    keymap = {
      accept = "<M-l>",
      next = "<M-]>",
      prev = "<M-[>",
      dismiss = "<M-e>",
    },
  },
})

local dap = require("dap")
local dapui = require("dapui")
require("dap-go").setup()
dapui.setup()

dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
  dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
  dapui.close()
end

vim.keymap.set("n", "<F5>", dap.continue)
vim.keymap.set("n", "<F9>", dap.toggle_breakpoint)
vim.keymap.set("n", "<F10>", dap.step_over)
vim.keymap.set("n", "<F11>", dap.step_into)

local null_ls = require("null-ls")
local formatting_sources = {}

if vim.fn.executable("stylua") == 1 then
  table.insert(formatting_sources, null_ls.builtins.formatting.stylua)
end
if vim.fn.executable("prettierd") == 1 then
  table.insert(formatting_sources, null_ls.builtins.formatting.prettierd)
end
if vim.fn.executable("black") == 1 then
  table.insert(formatting_sources, null_ls.builtins.formatting.black)
end
if vim.fn.executable("isort") == 1 then
  table.insert(formatting_sources, null_ls.builtins.formatting.isort)
end

null_ls.setup({
  sources = formatting_sources,
})
vim.keymap.set("n", "<leader>cf", vim.lsp.buf.format)
