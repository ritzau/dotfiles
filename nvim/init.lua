-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Leader key (before plugins)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Common cleanup appended to every formatter chain
local function fmt(...)
  return { ..., "trim_whitespace", "trim_newlines" }
end

------------------------------------------------------------------------
-- Options
------------------------------------------------------------------------
vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true
vim.opt.scrolloff = 8
vim.opt.wildmode = "longest:full,full"

vim.opt.undofile = true
vim.opt.swapfile = false

vim.opt.updatetime = 250
vim.opt.clipboard = "unnamedplus"

vim.opt.completeopt = { "menu", "menuone", "noinsert", "fuzzy", "popup" }

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    vim.lsp.completion.enable(true, ev.data.client_id, ev.buf, { autotrigger = true })
    -- manual trigger
    vim.keymap.set("i", "<C-space>", vim.lsp.completion.get, { buffer = ev.buf })
  end,
})

vim.diagnostic.config({
  virtual_text = true,            -- message at end of line
  -- or:
  -- virtual_lines = { current_line = true },  -- full text under the current line
  severity_sort = true,
})

vim.opt.statusline = " %f %m%r %= %{v:lua.vim.lsp.status()} %l:%c "

vim.api.nvim_create_autocmd("LspProgress", {
  callback = function() vim.cmd.redrawstatus() end,
})

------------------------------------------------------------------------
-- Plugins
------------------------------------------------------------------------
-- init.lua is symlinked in from the dotfiles repo; resolve it so lazy writes
-- its lockfile next to this file instead of into ~/.config/nvim (untracked).
local init_path = vim.uv.fs_realpath(vim.fn.stdpath("config") .. "/init.lua")
local lockfile = init_path and (vim.fs.dirname(init_path) .. "/lazy-lock.json") or nil

require("lazy").setup({
  -- Quick navigation (replaces easymotion)
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    },
  },

  -- File browser
  {
    "stevearc/oil.nvim",
    lazy = false,
    opts = {
      delete_to_trash = true,
    },
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "Open parent directory" },
    },
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons", -- optional, needs a Nerd Font
    },
    keys = {
      { "<leader>e", "<cmd>Neotree toggle left<cr>", desc = "File tree" },
      { "<leader>E", "<cmd>Neotree focus<cr>", desc = "Focus tree" },
    },
    opts = {
      filesystem = {
        follow_current_file = { enabled = true },
        hijack_netrw_behavior = "disabled", -- let oil keep `nvim .`
      },
    },
  },

  -- Git
  { "tpope/vim-fugitive", cmd = "Git" },
  { "lewis6991/gitsigns.nvim", event = "BufReadPre",
    opts = {
      on_attach = function(buf)
        local gs = require("gitsigns")
        local map = function(l, r, desc) vim.keymap.set("n", l, r, { buffer = buf, desc = desc }) end
        map("]c", function() gs.nav_hunk("next") end, "Next hunk")
        map("[c", function() gs.nav_hunk("prev") end, "Prev hunk")
        map("<leader>hp", gs.preview_hunk, "Preview hunk")
        map("<leader>hs", gs.stage_hunk, "Stage hunk")
        map("<leader>hr", gs.reset_hunk, "Reset hunk")
        map("<leader>hb", gs.blame_line, "Blame line")
      end,
    },
  },
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diff vs index" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File history" },
    },
  },

  -- Treesitter (main branch: no more nvim-treesitter.configs module;
  -- parsers are installed via require("nvim-treesitter").install and
  -- highlighting/indent are enabled per-buffer with core vim.treesitter).
  -- Needs the `tree-sitter` CLI (in the flake) to compile parsers.
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")
      local languages = {
        "bash", "c", "cpp", "cuda", "go", "javascript", "json", "lua", "markdown", "markdown_inline",
        "python", "rust", "starlark", "yaml",
      }
      if vim.fn.executable("tree-sitter") == 1 then
        ts.install(languages)
      else
        vim.notify("nvim-treesitter: `tree-sitter` CLI not found; skipping parser install", vim.log.levels.WARN)
      end
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          if not pcall(vim.treesitter.start, args.buf) then
            return
          end
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },

  -- Fuzzy finder
  {
    "ibhagwan/fzf-lua",
    cmd = "FzfLua",
    keys = {
      { "<leader>f", function() require("fzf-lua").files() end, desc = "Find files" },
      { "<leader>g", function() require("fzf-lua").live_grep() end, desc = "Grep" },
      { "<leader>b", function() require("fzf-lua").buffers() end, desc = "Buffers" },
    },
  },

  -- LSP (server configs come from lspconfig; enabling is built into nvim)
  {
    "neovim/nvim-lspconfig",
    config = function()
      vim.lsp.config("clangd", {
        cmd = { "clangd", "--log=verbose", "--rename-file-limit=0", "--background-index" },
        filetypes = { "c", "cpp", "cuda" },
        capabilities = {
          workspace = { didChangeWatchedFiles = { dynamicRegistration = true } },
        },
      })
      vim.lsp.enable({ "clangd", "pylsp", "yamlls", "jsonls" })
    end,
  },

  -- Formatting
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        c = fmt("clang-format"),
        cpp = fmt("clang-format"),
        cuda = fmt("clang-format"),
        python = fmt("ruff_format"),
        sh = fmt("shfmt"),
        bash = fmt("shfmt"),
        yaml = fmt("yamlfmt"),
        json = fmt("biome"),
        jsonc = fmt("biome"),
        javascript = fmt("biome"),
        typescript = fmt("biome"),
        bzl = fmt("buildifier"),
        ["_"] = { "trim_whitespace", "trim_newlines" }, -- everything else
      },
      format_on_save = { timeout_ms = 1000, lsp_format = "fallback" },
    },
  },

  -- Coverage
  {
    "andythigpen/nvim-coverage",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "Coverage", "CoverageLoad", "CoverageToggle" },
    keys = {
      { "<leader>ct", "<cmd>CoverageToggle<CR>", desc = "Toggle coverage" },
      { "<leader>cl", "<cmd>CoverageLoad<CR>", desc = "Load coverage" },
      { "<leader>cs", "<cmd>CoverageSummary<CR>", desc = "Coverage summary" },
    },
    opts = {
      auto_reload = true,
      lang = {
        cpp = {
          coverage_file = function()
            return vim.fs.root(0, ".git") .. "/.cache/coverage/lcov.info"
          end,
        },
      },
    },
  },

  { "kylechui/nvim-surround", opts = {} },
  { "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} },
  { "HiPhish/rainbow-delimiters.nvim" },

  -- Theme
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("tokyonight")
    end,
  },
}, {
  lockfile = lockfile,
})

------------------------------------------------------------------------
-- Keymaps
------------------------------------------------------------------------
local map = vim.keymap.set

-- jk as Esc
vim.keymap.set("i", "jk", "<Esc>")
vim.opt.timeoutlen = 500

-- Window navigation
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

map("n", "<leader>a", "<cmd>LspClangdSwitchSourceHeader<cr>", { desc = "Source/header" })
