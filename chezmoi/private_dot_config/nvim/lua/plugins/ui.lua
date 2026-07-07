-- UI: Catppuccin Mocha theme (matches the workspace-wide theme) and which-key
-- (popup showing available keybindings after you press <leader>).
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = false,
      integrations = {
        gitsigns = true,
        neogit = true,
        which_key = true,
        snacks = true,
      },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme("catppuccin")
    end,
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
  },
}
