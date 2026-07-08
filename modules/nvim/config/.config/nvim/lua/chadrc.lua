-- This file needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :( 

---@type ChadrcConfig
local M = {}

M.base46 = {
	theme = "onedark",

	-- hl_override = {
	-- 	Comment = { italic = true },
	-- 	["@comment"] = { italic = true },
	-- },
}

-- Кликабельная кнопка Search в tabufline (вызывает GrugFar)
vim.cmd("function! TbOpenSearch(a,b,c,d) \n GrugFar \n endfunction")

M.ui = {
  tabufline = {
    lazyload = false,            -- панель вкладок всегда видна
    treeOffsetFt = "neo-tree",   -- offset для neo-tree (а не дефолтного NvimTree)
    order = { "treeOffset", "buffers", "tabs", "search_btn", "btns" },
    modules = {
      search_btn = function()
        local btn = require("nvchad.tabufline.utils").btn
        return btn("    Search ", "BufOff", "OpenSearch")
      end,
    },
  },
}

return M
