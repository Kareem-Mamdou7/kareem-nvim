return {
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles" },
    dependencies = { "nvim-tree/nvim-web-devicons" }, -- optional, for icons
    config = function()
      require("diffview").setup()
    end,
  },
}
