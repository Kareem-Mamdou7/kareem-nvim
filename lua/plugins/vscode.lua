return {
  "Mofiqul/vscode.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    require("vscode").setup({
      transparent = false, -- true to disable background
      italic_comments = true,
      disable_nvimtree_bg = true,
    })
    vim.cmd("colorscheme vscode")
  end,
}
