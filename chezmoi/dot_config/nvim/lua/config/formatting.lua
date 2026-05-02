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
