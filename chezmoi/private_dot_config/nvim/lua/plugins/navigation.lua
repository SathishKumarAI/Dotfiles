-- Navigation: Snacks (picker + notifications + lazygit float) and Oil (file
-- browser that edits the filesystem like a buffer). Snacks.picker replaces
-- Telescope; ripgrep powers the grep picker.
return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      picker = { enabled = true },
      notifier = { enabled = true },
      bigfile = { enabled = true },
      quickfile = { enabled = true },
    },
    keys = {
      { "<leader>ff", function() Snacks.picker.files() end, desc = "Find files" },
      { "<leader>fg", function() Snacks.picker.grep() end, desc = "Grep" },
      { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
      { "<leader>fh", function() Snacks.picker.help() end, desc = "Help pages" },
      { "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent files" },
    },
  },
  {
    "stevearc/oil.nvim",
    lazy = false,
    opts = {
      view_options = { show_hidden = true },
      keymaps = { ["q"] = "actions.close" },
    },
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "Open parent dir (Oil)" },
      { "<leader>e", "<cmd>Oil<cr>", desc = "File explorer (Oil)" },
    },
  },
}
