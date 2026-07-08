require "nvchad.autocmds"

-- Markdown winbar: breadcrumbs из заголовков + кликабельные кнопки Preview/Raw
local md_state = {} -- per-buffer: true = preview, false = raw

-- Хлебные крошки: путь к файлу (inbox › 2026-05-15_file.md)
function _G.MdBreadcrumbs()
  local rel_path = vim.fn.expand("%:.") -- путь относительно cwd
  if rel_path == "" then
    return "  [No Name]"
  end
  local parts = {}
  for part in string.gmatch(rel_path, "[^/]+") do
    table.insert(parts, part)
  end
  return "  " .. table.concat(parts, "  ›  ")
end

local function md_winbar(buf)
  local preview = md_state[buf] ~= false
  local toggle
  if preview then
    toggle = "%@v:lua.MdSetRaw@  Raw%X     Preview "
  else
    toggle = "   Raw     %@v:lua.MdSetPreview@  Preview%X "
  end
  return "%{%v:lua.MdBreadcrumbs()%}%=" .. toggle
end

function _G.MdSetPreview()
  local buf = vim.api.nvim_get_current_buf()
  md_state[buf] = true
  require("render-markdown").enable()
  vim.opt_local.winbar = md_winbar(buf)
end

function _G.MdSetRaw()
  local buf = vim.api.nvim_get_current_buf()
  md_state[buf] = false
  require("render-markdown").disable()
  vim.opt_local.winbar = md_winbar(buf)
end

function _G.MdTogglePreview()
  local buf = vim.api.nvim_get_current_buf()
  if md_state[buf] ~= false then
    _G.MdSetRaw()
  else
    _G.MdSetPreview()
  end
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    md_state[buf] = true
    vim.opt_local.winbar = md_winbar(buf)
  end,
})

-- В окне neo-tree выключаем всё, что может мешать или вызывать перерисовку
vim.api.nvim_create_autocmd("FileType", {
  pattern = "neo-tree",
  callback = function()
    pcall(vim.treesitter.stop)
    vim.opt_local.foldcolumn = "0"
    vim.opt_local.statuscolumn = ""
    vim.opt_local.signcolumn = "no"
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.foldenable = false
    vim.opt_local.cursorline = true
  end,
})

-- Авто-обновление neo-tree git_status: после сохранения файла + при возврате фокуса
local function refresh_neotree_git()
  local ok, manager = pcall(require, "neo-tree.sources.manager")
  if ok then
    pcall(manager.refresh, "git_status")
    pcall(manager.refresh, "filesystem")
  end
end

vim.api.nvim_create_autocmd({ "BufWritePost", "FocusGained" }, {
  callback = refresh_neotree_git,
})

-- Когда курсор заходит в окно neo-tree — тоже обновляем
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    if vim.bo.filetype == "neo-tree" then
      refresh_neotree_git()
    end
  end,
})
