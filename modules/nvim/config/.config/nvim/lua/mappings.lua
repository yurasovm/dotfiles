require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })

-- Выход из Insert: и jk, и kj (любая последовательность букв) → Esc
map("i", "jk", "<ESC>")
map("i", "kj", "<ESC>")

-- New file (как Ctrl+N в VSCode — открыть пустой буфер)
map("n", "<C-n>", "<cmd>enew<CR>", { desc = "New file (empty buffer)" })

-- Quick Open: Ctrl+P — fuzzy поиск файлов в VSCode-стиле (имя слева, путь справа, без preview)
-- Search/Replace в файле (VSCode-style)
-- Ctrl+F — поиск (нативное /), Ctrl+H — поиск и замена в файле
map({ "n", "i" }, "<C-f>", "<Esc>/",                    { desc = "Find in file" })
map({ "n", "i" }, "<C-h>", "<Esc>:%s/",                 { desc = "Find & replace in file" })
map("v",          "<C-h>", ":s/",                       { desc = "Find & replace in selection" })

map("n", "<C-p>", function()
  require("telescope.builtin").find_files({
    prompt_title = "",
    previewer = false,
    path_display = { "filename_first" },
    layout_strategy = "horizontal",
    layout_config = {
      width = 0.7,
      height = 0.5,
      prompt_position = "top",
    },
    sorting_strategy = "ascending",
    results_title = false,
  })
end, { desc = "Quick Open" })

map("n", "<C-S-p>", "<cmd>Telescope commands<CR>",  { desc = "Command palette" })
map("n", "<C-S-f>", "<cmd>Telescope live_grep<CR>", { desc = "Find in files (quick)" })
map("n", "<C-S-h>", "<cmd>GrugFar<CR>",             { desc = "Find & replace panel (VSCode-style)" })

-- Trigger suggest вручную: Shift+Space (как у тебя в VSCode)
map("i", "<S-Space>", function() require("cmp").complete() end, { desc = "Trigger autocomplete" })

-- Toggle comment: Ctrl+/ (VSCode-style). nvim видит <C-/> как <C-_>, мапим оба.
map("n", "<C-/>", "gcc",      { desc = "Toggle comment", remap = true })
map("n", "<C-_>", "gcc",      { desc = "Toggle comment", remap = true })
map("v", "<C-/>", "gc",       { desc = "Toggle comment", remap = true })
map("v", "<C-_>", "gc",       { desc = "Toggle comment", remap = true })
map("i", "<C-/>", "<Esc>gcca",{ desc = "Toggle comment", remap = true })
map("i", "<C-_>", "<Esc>gcca",{ desc = "Toggle comment", remap = true })

-- Goto symbol в файле (VSCode: Cmd+Shift+O)
map("n", "<C-S-o>", "<cmd>Telescope lsp_document_symbols<CR>", { desc = "Goto symbol" })

-- Toggle отображения невидимых символов (точки/табы/trailing)
map("n", "<leader>ts", "<cmd>set list!<CR>", { desc = "Toggle whitespace chars" })

-- Tab / Shift-Tab — сдвиг блока вправо/влево, выделение сохраняется
-- Visual mode
map("x", "<Tab>",   ">gv", { desc = "Indent selection" })
map("x", "<S-Tab>", "<gv", { desc = "Dedent selection" })
-- Select mode (VSCode-style): <C-g> переключает в Visual, после indent — обратно в Select
map("s", "<Tab>",   "<C-g>>gv<C-g>", { desc = "Indent selection" })
map("s", "<S-Tab>", "<C-g><gv<C-g>", { desc = "Dedent selection" })

-- ===== Навигация: слова (Option) и края строки (Ctrl), mac/VSCode-style =====

-- Option+Left/Right — прыжок через слово
map({ "n", "x" }, "<M-Left>",  "b", { desc = "Word back" })
map({ "n", "x" }, "<M-Right>", "w", { desc = "Word forward" })
map("i", "<M-Left>",  "<C-\\><C-O>b", { desc = "Word back" })
map("i", "<M-Right>", "<C-\\><C-O>w", { desc = "Word forward" })

-- Home/End — умный Home (^ ↔ 0) и обычный End.
-- Cmd+Left/Right в Ghostty прокинуты как Home/End (см. ghostty/config).
local function smart_home()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local first_nonblank = (line:find("%S") or 1) - 1
  if col == first_nonblank then
    vim.api.nvim_win_set_cursor(0, { row, 0 })
  else
    vim.api.nvim_win_set_cursor(0, { row, first_nonblank })
  end
end

map({ "n", "x", "i" }, "<Home>", smart_home, { desc = "Smart home" })
map({ "n", "x", "i" }, "<End>",  function()
  local row = vim.fn.line(".")
  local len = vim.fn.col({ row, "$" }) - 1
  vim.api.nvim_win_set_cursor(0, { row, math.max(len - 1, 0) })
end, { desc = "End of line" })

-- Option/Alt + Backspace — удалить слово назад
map("i", "<M-BS>", "<C-w>",         { desc = "Delete word back" })
map("c", "<M-BS>", "<C-w>",         { desc = "Delete word back (cmd)" })
map("n", "<M-BS>", "db",            { desc = "Delete word back" })

-- Option/Alt + Up/Down — перенос строки или выделенного блока
-- silent! глушит ошибку "invalid range" на крайних строках
map("n", "<M-Down>", "<cmd>silent! m .+1<CR><cmd>silent! normal! ==<CR>",       { desc = "Move line down" })
map("n", "<M-Up>",   "<cmd>silent! m .-2<CR><cmd>silent! normal! ==<CR>",       { desc = "Move line up" })
map("i", "<M-Down>", "<Esc><cmd>silent! m .+1<CR><cmd>silent! normal! ==<CR>gi",{ desc = "Move line down" })
map("i", "<M-Up>",   "<Esc><cmd>silent! m .-2<CR><cmd>silent! normal! ==<CR>gi",{ desc = "Move line up" })
-- v = visual + select; <C-\><C-N> выходим из Select в Normal, чтобы выполнить :команду
map("v", "<M-Down>", "<C-\\><C-N><cmd>silent! '<,'>m '>+1<CR>gv=gv",            { desc = "Move selection down" })
map("v", "<M-Up>",   "<C-\\><C-N><cmd>silent! '<,'>m '<-2<CR>gv=gv",            { desc = "Move selection up" })
-- VSCode-привычка: Ctrl+Up/Down тоже двигают строки
map("n", "<C-Down>", "<cmd>silent! m .+1<CR><cmd>silent! normal! ==<CR>",       { desc = "Move line down" })
map("n", "<C-Up>",   "<cmd>silent! m .-2<CR><cmd>silent! normal! ==<CR>",       { desc = "Move line up" })
map("i", "<C-Down>", "<Esc><cmd>silent! m .+1<CR><cmd>silent! normal! ==<CR>gi",{ desc = "Move line down" })
map("i", "<C-Up>",   "<Esc><cmd>silent! m .-2<CR><cmd>silent! normal! ==<CR>gi",{ desc = "Move line up" })
map("v", "<C-Down>", "<C-\\><C-N><cmd>silent! '<,'>m '>+1<CR>gv=gv",            { desc = "Move selection down" })
map("v", "<C-Up>",   "<C-\\><C-N><cmd>silent! '<,'>m '<-2<CR>gv=gv",            { desc = "Move selection up" })

-- Option+Shift+Left/Right — выделение по словам (VSCode-style)
-- v<motion><C-g>: visual + word motion + переключение в Select mode (буква заменит)
map("n", "<M-S-Right>", "vw<C-g>",       { desc = "Select word forward" })
map("n", "<M-S-Left>",  "vb<C-g>",       { desc = "Select word back" })
map("i", "<M-S-Right>", "<Esc>vw<C-g>",  { desc = "Select word forward" })
map("i", "<M-S-Left>",  "<Esc>vb<C-g>",  { desc = "Select word back" })
-- В Select mode: переходим в Visual, делаем word motion, возвращаемся в Select
map("s", "<M-S-Right>", "<C-g>w<C-g>",   { desc = "Extend by word" })
map("s", "<M-S-Left>",  "<C-g>b<C-g>",   { desc = "Extend by word" })
map("x", "<M-S-Right>", "w",             { desc = "Extend by word" })
map("x", "<M-S-Left>",  "b",             { desc = "Extend by word" })

-- Shift+Home/End — выделение к началу/концу строки.
-- Smart-Home для расширения: первое нажатие — к первому non-blank (^),
-- второе — к колонке 0. Используем expr-mapping чтобы выбирать motion в момент нажатия.
local function home_motion()
  local _, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local first_nonblank = (line:find("%S") or 1) - 1
  return (col == first_nonblank) and "0" or "^"
end

local expr_opts = { expr = true, replace_keycodes = true }

map("n", "<S-Home>", function() return "v" .. home_motion() .. "<C-g>" end,
  vim.tbl_extend("force", expr_opts, { desc = "Select to start of line" }))
map("i", "<S-Home>", function() return "<Esc>v" .. home_motion() .. "<C-g>" end,
  vim.tbl_extend("force", expr_opts, { desc = "Select to start of line" }))
map("s", "<S-Home>", function() return "<C-g>" .. home_motion() .. "<C-g>" end,
  vim.tbl_extend("force", expr_opts, { desc = "Extend to start of line" }))
map("x", "<S-Home>", function() return home_motion() end,
  vim.tbl_extend("force", expr_opts, { desc = "Extend to start of line" }))

-- Shift+End — выделение к концу строки (без double-press, $ единственная цель)
map("n", "<S-End>", "v$<C-g>",      { desc = "Select to end of line" })
map("i", "<S-End>", "<Esc>v$<C-g>", { desc = "Select to end of line" })
map("s", "<S-End>", "<C-g>$<C-g>",  { desc = "Extend to end of line" })
map("x", "<S-End>", "$",            { desc = "Extend to end of line" })

-- Форматирование (VSCode: Shift+Alt+F). У нас на <leader>fm и <C-A-l>
map({ "n", "v" }, "<leader>fm", function()
  require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "Format file/selection" })
map({ "n", "v" }, "<C-A-l>", function()
  require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "Format file/selection" })

-- VSCode-style редактирование
-- Ctrl+K — удалить текущую строку (или выделенные строки)
-- (Ctrl+Shift+K в обычном терминале неотличим от Ctrl+K, поэтому без Shift)
map("n", "<C-k>", "<cmd>delete<CR>",        { desc = "Delete line" })
map("i", "<C-k>", "<Esc><cmd>delete<CR>gi", { desc = "Delete line" })
map("x", "<C-k>", ":<C-u>'<,'>delete<CR>",  { desc = "Delete lines" })

-- Ctrl+D — продублировать строку (или выделение). VSCode duplicate.
-- (VSCode по умолчанию Shift+Alt+Down, но <C-d> привычнее)
map("n", "<C-d>", "<cmd>copy .<CR>",   { desc = "Duplicate line" })
map("x", "<C-d>", "y'>p",              { desc = "Duplicate selection" })

-- Shift+Alt+Down / Up — дублировать строку или выделение (VSCode default)
map("n", "<M-S-Down>", "<cmd>copy .<CR>",          { desc = "Duplicate line down" })
map("n", "<M-S-Up>",   "<cmd>copy .-1<CR>",        { desc = "Duplicate line up" })
map("i", "<M-S-Down>", "<Esc><cmd>copy .<CR>gi",   { desc = "Duplicate line down" })
map("i", "<M-S-Up>",   "<Esc><cmd>copy .-1<CR>gi", { desc = "Duplicate line up" })
-- Visual mode: дублировать выделенный кусок
map("x", "<M-S-Down>", "y`>p", { desc = "Duplicate selection down" })
map("x", "<M-S-Up>",   "y`<P", { desc = "Duplicate selection up" })
-- Select mode: <C-g> → Visual, yank+paste
map("s", "<M-S-Down>", "<C-g>y`>p", { desc = "Duplicate selection down" })
map("s", "<M-S-Up>",   "<C-g>y`<P", { desc = "Duplicate selection up" })

-- Найти текущий файл в neo-tree (как VSCode Reveal in File Explorer)
map("n", "<leader>br", "<cmd>Neotree reveal<CR>", { desc = "Reveal current file in tree" })

-- File tree (VSCode-style, с вкладками Files / Git / Bufs)
-- Smart toggle: открыть+фокус → закрыть только если фокус уже в дереве
map("n", "<C-b>", function()
  if vim.bo.filetype == "neo-tree" then
    vim.cmd("Neotree close")
  else
    vim.cmd("Neotree focus")
  end
end, { desc = "Toggle/focus file tree" })

-- Save: если буфер без имени — спросим путь, иначе обычное :w
map({ "n", "i", "v" }, "<C-s>", function()
  -- выйти из insert если мы в нём
  if vim.fn.mode() == "i" then
    vim.cmd("stopinsert")
  end
  if vim.fn.expand("%") == "" then
    vim.ui.input({
      prompt = "Save as: ",
      default = vim.fn.getcwd() .. "/",
      completion = "file",
    }, function(name)
      if name and name ~= "" then
        vim.cmd("saveas " .. vim.fn.fnameescape(name))
      end
    end)
  else
    vim.cmd("silent write")
  end
end, { desc = "Save file" })

-- Undo / Redo
map("n", "<C-z>", "u",         { desc = "Undo" })
map("i", "<C-z>", "<Esc>u",    { desc = "Undo" })
map("n", "<C-y>", "<C-r>",     { desc = "Redo" })
map("i", "<C-y>", "<Esc><C-r>",{ desc = "Redo" })

-- Clipboard: copy/cut/paste через системный буфер
map("v", "<C-c>", '"+y', { desc = "Copy to clipboard" })
map("v", "<C-x>", '"+d', { desc = "Cut to clipboard" })
map({ "n", "i", "v" }, "<C-v>", '"+p', { desc = "Paste from clipboard" })

-- Select all
map({ "n", "i" }, "<C-a>", "<cmd>normal! ggVG<CR>", { desc = "Select all" })

-- Close / Quit
map("n", "<C-q>", "<cmd>confirm bd<CR>",  { desc = "Close buffer" })
map("n", "<C-S-q>", "<cmd>confirm qa<CR>", { desc = "Quit Neovim" })

-- Problems panel (VSCode-style)
map("n", "<C-S-m>", "<cmd>Trouble diagnostics toggle<CR>", { desc = "Toggle Problems panel" })

-- Терминалы (toggleterm): 1/2/3 — конкретные, tt — список, tn — новый
map("n", "<leader>t1", "<cmd>1ToggleTerm direction=horizontal<CR>", { desc = "Terminal 1" })
map("n", "<leader>t2", "<cmd>2ToggleTerm direction=horizontal<CR>", { desc = "Terminal 2" })
map("n", "<leader>t3", "<cmd>3ToggleTerm direction=horizontal<CR>", { desc = "Terminal 3" })
map("n", "<leader>tt", "<cmd>TermSelect<CR>",                       { desc = "Terminal: select from list" })
map("n", "<leader>tn", "<cmd>ToggleTerm direction=float<CR>",       { desc = "Terminal: floating" })

-- Из terminal mode выйти в Normal: <Esc><Esc> (двойной)
map("t", "<Esc><Esc>", [[<C-\><C-n>]], { desc = "Terminal: leave to normal" })

-- Git diff view (VSCode-style Source Control)
local diffview_open = false
map("n", "<C-S-g>", function()
  if diffview_open then
    vim.cmd "DiffviewClose"
    diffview_open = false
  else
    vim.cmd "DiffviewOpen"
    diffview_open = true
  end
end, { desc = "Toggle git diff view" })

-- Markdown: переключение Preview/Raw
map("n", "<leader>mp", function() _G.MdTogglePreview() end, { desc = "Markdown: Preview/Raw toggle" })

-- Сворачивание секций
map("n", "zR", function() require("ufo").openAllFolds() end,  { desc = "Развернуть все" })
map("n", "zM", function() require("ufo").closeAllFolds() end, { desc = "Свернуть все" })
map("n", "za", "za", { desc = "Переключить секцию" })

-- Должно быть последним: дублирует все маппинги для русской раскладки
vim.schedule(function()
  require("langmapper").automapping { global = true, buffer = false }
end)
