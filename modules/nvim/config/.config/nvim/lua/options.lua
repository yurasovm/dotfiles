require "nvchad.options"

-- Обнуляем дефолтное действие пробела (в normal/visual он по умолчанию движет курсор)
-- Без этого <Space> как leader-префикс работает дёргано: курсор успевает шагнуть.
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- Время ожидания продолжения комбинации (попап which-key)
vim.opt.timeoutlen = 400

-- ESC sequences (CSI/SS3) должны успеть прийти после <Esc>.
-- Если ttimeoutlen слишком велик — медленный Esc; слишком мал — Home/End/F-keys
-- ломаются (читаются как Esc + остальное и выкидывают из insert).
-- 10мс хватает для Ghostty + tmux.
vim.opt.ttimeout = true
vim.opt.ttimeoutlen = 10

-- VSCode-style выделение через Shift+стрелки:
--   keymodel.startsel  — Shift+motion начинает выделение
--   keymodel.stopsel   — обычный motion (без Shift) завершает выделение
--   selectmode.key     — выделение начинается в Select mode, не Visual
--                        (печатаемый символ заменяет выделение — как в VSCode)
vim.opt.keymodel = { "startsel", "stopsel" }
vim.opt.selectmode = { "key" }

-- Obsidian Bases (.base) — это YAML
vim.filetype.add {
  extension = {
    base = "yaml",
  },
}

-- Не переносить длинные строки, скроллить горизонтально
vim.opt.wrap = false
vim.opt.sidescroll = 1
vim.opt.sidescrolloff = 8

-- Невидимые символы (как VSCode renderWhitespace: all)
vim.opt.list = true
vim.opt.listchars = {
  tab      = "→ ",   -- табы — стрелка
  space    = "·",    -- пробелы — точка
  trail    = "•",    -- конечные пробелы — жирная точка (заметнее)
  nbsp     = "␣",    -- non-breaking space
  extends  = "⟩",    -- строка обрезана справа
  precedes = "⟨",    -- строка обрезана слева
}
