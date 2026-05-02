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
