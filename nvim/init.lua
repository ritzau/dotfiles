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

------------------------------------------------------------------------
-- Options
------------------------------------------------------------------------
vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
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

vim.opt.undofile = true
vim.opt.swapfile = false

vim.opt.updatetime = 250
vim.opt.clipboard = "unnamedplus"

------------------------------------------------------------------------
-- Plugins
------------------------------------------------------------------------
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

  -- Git
  { "tpope/vim-fugitive", cmd = "Git" },
  { "lewis6991/gitsigns.nvim", event = "BufReadPre", opts = {} },

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
        "bash", "c", "go", "json", "lua", "markdown", "markdown_inline",
        "python", "rust", "yaml",
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

  -- Theme
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("tokyonight")
    end,
  },
})

------------------------------------------------------------------------
-- Keymaps
------------------------------------------------------------------------
local map = vim.keymap.set

-- Window navigation
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR>")
