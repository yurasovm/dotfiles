local options = {
  formatters_by_ft = {
    lua  = { "stylua" },
    json = { "jq" },
  },

  -- format_on_save = {
  --   timeout_ms = 500,
  --   lsp_fallback = true,
  -- },
}

return options
