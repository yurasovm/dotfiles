return {
  -- Markdown preview прямо в буфере
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    opts = { enabled = true },
  },

  -- Колонка слева с кликабельными маркерами сворачивания
  {
    "luukvbaal/statuscol.nvim",
    event = "BufReadPost",
    config = function()
      local builtin = require("statuscol.builtin")
      require("statuscol").setup {
        relculright = true,
        ft_ignore = { "neo-tree", "NvimTree", "help", "lazy", "mason", "TelescopePrompt" },
        bt_ignore = { "nofile", "prompt", "terminal" },
        segments = {
          { text = { builtin.foldfunc }, click = "v:lua.ScFa" },
          { text = { "%s" },            click = "v:lua.ScSa" },
          { text = { builtin.lnumfunc, " " }, click = "v:lua.ScLa" },
        },
      }
    end,
  },

  -- Умное сворачивание секций (YAML, JSON, Lua, и т.д.)
  {
    "kevinhwang91/nvim-ufo",
    dependencies = { "kevinhwang91/promise-async" },
    event = "BufReadPost",
    config = function()
      require("ufo").setup {
        provider_selector = function(_, filetype, _)
          if filetype == "neo-tree" or filetype == "NvimTree" or filetype == "" then
            return ""
          end
          return { "treesitter", "indent" }
        end,
        fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
          local newVirtText = {}
          local suffix = ("  %d lines"):format(endLnum - lnum)
          local sufWidth = vim.fn.strdisplaywidth(suffix)
          local targetWidth = width - sufWidth
          local curWidth = 0
          for _, chunk in ipairs(virtText) do
            local chunkText = chunk[1]
            local chunkWidth = vim.fn.strdisplaywidth(chunkText)
            if targetWidth > curWidth + chunkWidth then
              table.insert(newVirtText, chunk)
            else
              chunkText = truncate(chunkText, targetWidth - curWidth)
              table.insert(newVirtText, { chunkText, chunk[2] })
              break
            end
            curWidth = curWidth + chunkWidth
          end
          table.insert(newVirtText, { suffix, "Comment" })
          return newVirtText
        end,
      }
      vim.o.foldcolumn = "1"
      vim.o.foldlevel = 99
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true
    end,
  },

  -- Работа клавиш в любой раскладке
  {
    "Wansmer/langmapper.nvim",
    lazy = false,
    priority = 1,
    config = function()
      require("langmapper").setup { auto_map = true }
    end,
  },

  -- Заменяем nvim-tree на neo-tree с вкладками Files / Git / Buffers
  {
    "nvim-tree/nvim-tree.lua",
    enabled = false,
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    cmd = "Neotree",
    config = function()
      require("neo-tree").setup {
        close_if_last_window = true,
        enable_diagnostics = false,
        hide_root_node = true,
        retain_hidden_root_indent = false,

        sources = { "filesystem", "git_status", "buffers" },
        source_selector = {
          winbar = true,
          separator = "",
          tabs_layout = "equal",
          sources = {
            { source = "filesystem", display_name = "  Files" },
            { source = "git_status", display_name = "  Git" },
            { source = "buffers",    display_name = "  Bufs" },
          },
        },

        default_component_configs = {
          indent = {
            indent_size = 2,
            padding = 1,
            with_markers = true,
            indent_marker = "│",
            last_indent_marker = "└",
            with_expanders = true,
            expander_collapsed = "",
            expander_expanded = "",
          },
          name = { trailing_slash = false, use_git_status_colors = true },
          git_status = {
            symbols = {
              added     = "",
              modified  = "",
              deleted   = "✖",
              renamed   = "󰁕",
              untracked = "",
              ignored   = "",
              unstaged  = "󰄱",
              staged    = "",
              conflict  = "",
            },
          },
        },

        window = {
          width = 30,
          mappings = {
            -- Перекрываем дефолтный scroll_preview, чтобы C-b закрывал дерево
            ["<C-b>"] = function() vim.cmd("Neotree close") end,
            ["O"] = "open_in_finder",
            -- Правый клик → контекстное меню
            ["<RightMouse>"]  = "context_menu",
            ["<RightRelease>"] = "noop",  -- не дублировать
          },
        },

        commands = {
          -- Открыть в файловом менеджере: macOS — Finder (reveal файла),
          -- Linux — xdg-open (для файла открываем родительскую папку).
          open_in_finder = function(state)
            local node = state.tree:get_node()
            if not node then return end
            local path = node.path
            local is_dir = node.type == "directory"
            if vim.fn.has("mac") == 1 then
              if is_dir then
                vim.fn.jobstart({ "open", path }, { detach = true })
              else
                vim.fn.jobstart({ "open", "-R", path }, { detach = true })
              end
            else
              local target = is_dir and path or vim.fn.fnamemodify(path, ":h")
              vim.fn.jobstart({ "xdg-open", target }, { detach = true })
            end
          end,

          noop = function() end,

          -- Контекстное меню (правый клик)
          context_menu = function(state)
            local node = state.tree:get_node()
            if not node then return end

            -- сначала кликом ставим выделение на узел под курсором
            require("neo-tree.ui.renderer").focus_node(state, node:get_id())

            local items = {
              { label = "Open",            cmd = "open" },
              { label = "Open in Finder",  cmd = "open_in_finder" },
              { label = "Search in Project", cmd = "search_project" },
              { label = "─────────────" },
              { label = "Cut",             cmd = "cut_to_clipboard" },
              { label = "Copy",            cmd = "copy_to_clipboard" },
              { label = "Paste",           cmd = "paste_from_clipboard" },
              { label = "─────────────" },
              { label = "Rename",          cmd = "rename" },
              { label = "Delete",          cmd = "delete" },
              { label = "─────────────" },
              { label = "Copy Path",       cmd = "copy_path" },
              { label = "Copy Name",       cmd = "copy_filename" },
              { label = "New File",        cmd = "add" },
              { label = "New Folder",      cmd = "add_directory" },
            }

            vim.ui.select(items, {
              prompt = node.name,
              format_item = function(item) return item.label end,
            }, function(choice)
              if not choice or not choice.cmd then return end
              local cmds = require("neo-tree.sources.filesystem.commands")
              local action = cmds[choice.cmd]
              if action then
                action(state)
              end
            end)
          end,

          copy_path = function(state)
            local node = state.tree:get_node()
            if node then
              vim.fn.setreg("+", node.path)
              vim.notify("Copied path: " .. node.path)
            end
          end,

          copy_filename = function(state)
            local node = state.tree:get_node()
            if node then
              vim.fn.setreg("+", node.name)
              vim.notify("Copied name: " .. node.name)
            end
          end,

          search_project = function() vim.cmd("GrugFar") end,
        },

        filesystem = {
          follow_current_file = {
            enabled = true,           -- при переключении буфера выделить файл в дереве
            leave_dirs_open = true,   -- не сворачивать открытые ранее папки
          },
          hijack_netrw_behavior = "disabled",
          use_libuv_file_watcher = false,
          filtered_items = {
            hide_dotfiles = false,
            hide_gitignored = false,
            -- never_show — папки/файлы которые НИКОГДА не показывать,
            -- даже при toggle show-hidden.
            never_show = { ".git", ".DS_Store" },
          },
        },

      }
    end,
  },

  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose" },
  },

  -- Современный UI: cmdline в центре, красивые hover/signature, прогресс-бары
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    opts = {
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
      },
      presets = {
        bottom_search = false,       -- поиск тоже в центре
        command_palette = true,      -- cmdline и popup-меню в одном месте
        long_message_to_split = true,
        lsp_doc_border = true,
      },
      routes = {
        -- скрыть «written» спам при сохранении
        { filter = { event = "msg_show", kind = "", find = "written" }, opts = { skip = true } },
      },
    },
  },

  -- Панель «Problems» снизу: ошибки/предупреждения по проекту
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = {
      focus = true,
      auto_close = true,
    },
  },

  -- Breadcrumbs в winbar: путь до текущей функции/секции
  {
    "Bekaboo/dropbar.nvim",
    event = "BufReadPost",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("dropbar").setup {
        bar = {
          -- не показывать в служебных буферах
          enable = function(buf, win, _)
            if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(win) then
              return false
            end
            local ft = vim.bo[buf].filetype
            local bt = vim.bo[buf].buftype
            if bt ~= "" then return false end
            -- markdown обслуживаем сами (breadcrumbs из заголовков + Preview/Raw)
            if ft == "neo-tree" or ft == "NvimTree" or ft == "markdown" then
              return false
            end
            return vim.fn.win_gettype(win) == ""
          end,
        },
      }
    end,
  },

  -- Терминалы внутри nvim: несколько, с переключением как вкладки VSCode
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd = { "ToggleTerm", "ToggleTermAll", "TermSelect" },
    keys = {
      { [[<C-\>]], mode = { "n", "t" } },
      { "<leader>t1", mode = "n" },
      { "<leader>t2", mode = "n" },
      { "<leader>t3", mode = "n" },
      { "<leader>tt", mode = "n" },
      { "<leader>tn", mode = "n" },
    },
    opts = {
      open_mapping = [[<C-\>]],     -- Ctrl+\ — открыть/закрыть последний
      direction = "horizontal",      -- терминал снизу как в VSCode
      size = 15,
      persist_size = true,
      persist_mode = true,
      start_in_insert = true,
      insert_mappings = true,
      terminal_mappings = true,
      close_on_exit = true,
      auto_scroll = true,
      shade_terminals = true,
      shading_factor = 2,
    },
  },

  -- VSCode-like scrollbar справа с гит-маркерами и диагностикой по ВСЕМУ файлу
  {
    "lewis6991/satellite.nvim",
    event = "BufReadPost",
    opts = {
      current_only = false,
      winblend = 50,
      zindex = 40,
      excluded_filetypes = { "neo-tree", "NvimTree", "help", "lazy", "mason", "trouble" },
      handlers = {
        cursor      = { enable = true },
        search      = { enable = true },
        diagnostic  = { enable = true, signs = { "-", "=", "≡" } },
        gitsigns    = { enable = true },
        marks       = { enable = false },
        quickfix    = { enable = true },
      },
    },
  },


  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- test new blink
  -- { import = "nvchad.blink.lazyspec" },

  -- Search & Replace по всему проекту с include/exclude (как VSCode search panel)
  {
    "MagicDuck/grug-far.nvim",
    cmd = { "GrugFar", "GrugFarWithin" },
    opts = {
      headerMaxWidth = 80,
      windowCreationCommand = "vsplit",
    },
  },

  -- Автоподсветка вхождений слова под курсором (как VSCode)
  {
    "RRethy/vim-illuminate",
    event = "BufReadPost",
    config = function()
      require("illuminate").configure({
        providers = { "lsp", "treesitter", "regex" },
        delay = 150,
        filetypes_denylist = { "neo-tree", "NvimTree", "TelescopePrompt", "lazy", "mason", "trouble" },
      })

      -- Подсветка фоном (как маркер), а не подчёркиванием.
      -- Линкуем на Visual — фон совпадёт с цветом visual-selection текущей темы.
      local set_hl = function()
        vim.api.nvim_set_hl(0, "IlluminatedWordText",  { link = "Visual" })
        vim.api.nvim_set_hl(0, "IlluminatedWordRead",  { link = "Visual" })
        vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { link = "Visual" })
      end
      set_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_hl })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = function() require("nvim-treesitter").update() end,
    config = function()
      local langs = {
        "html", "css", "javascript", "typescript", "tsx",
        "lua", "luadoc", "vim", "vimdoc", "query",
        "json", "yaml", "toml",
        "markdown", "markdown_inline",
        "bash", "regex", "php", "phpdoc",
      }
      require("nvim-treesitter").install(langs)

      -- Запускаем treesitter (syntax + folds) для перечисленных filetype.
      -- Парсер автоматически подцепляется по filetype.
      vim.api.nvim_create_autocmd("FileType", {
        pattern = {
          "html", "css", "javascript", "typescript", "typescriptreact",
          "lua", "vim", "help", "query",
          "json", "yaml", "toml",
          "markdown",
          "sh", "bash", "php",
        },
        callback = function()
          pcall(vim.treesitter.start)
        end,
      })
    end,
  },
}
