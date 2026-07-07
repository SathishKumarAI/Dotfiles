-- Neovim config — managed by chezmoi.
-- Entry point: set leader, load core (no-plugin) config, bootstrap lazy.nvim,
-- then load plugin specs from lua/plugins/. Existing options + keymaps live in
-- vim_config.lua / keys.lua unchanged.

-- Leader MUST be set before lazy so plugin mappings register under it.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Core editor config (works with zero plugins installed).
require("vim_config")
require("keys")

-- Bootstrap lazy.nvim (clones itself on first launch).
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Load every spec file under lua/plugins/.
require("lazy").setup({
  spec = { { import = "plugins" } },
  install = { colorscheme = { "catppuccin" } },
  checker = { enabled = false }, -- no auto update-check nag
  change_detection = { notify = false },
})
