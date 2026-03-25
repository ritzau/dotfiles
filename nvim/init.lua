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

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = "BufReadPost",
    opts = {
      ensure_installed = {
        "bash", "c", "go", "json", "lua", "markdown", "python", "rust", "yaml",
      },
      highlight = { enable = true },
      indent = { enable = true },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
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
