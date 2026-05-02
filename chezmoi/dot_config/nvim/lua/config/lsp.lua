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
