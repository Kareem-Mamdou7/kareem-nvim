return {
  {
    "shaunsingh/nord.nvim",
    priority = 1000, -- make sure it loads before everything else
    config = function()
      vim.cmd([[colorscheme nord]])
    end,
  },
}
