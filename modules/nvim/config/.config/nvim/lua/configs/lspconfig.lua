require("nvchad.configs.lspconfig").defaults()

-- Включаем только те LSP, у которых реально установлен бинарь.
-- Иначе при открытии файла появляется ошибка spawn.
local candidates = {
  html        = "vscode-html-language-server",
  cssls       = "vscode-css-language-server",
  tailwindcss = "tailwindcss-language-server",
}

local enabled = {}
for server, bin in pairs(candidates) do
  if vim.fn.executable(bin) == 1 then
    table.insert(enabled, server)
  end
end

if #enabled > 0 then
  vim.lsp.enable(enabled)
end

-- Установить недостающие: :MasonInstall html-lsp css-lsp tailwindcss-language-server
-- read :h vim.lsp.config for changing options of lsp servers
