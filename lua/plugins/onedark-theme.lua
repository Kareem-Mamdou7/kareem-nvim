return {
  "navarasu/onedark.nvim",
  lazy = false, -- Load immediately
  priority = 1000, -- Ensure it's loaded before other UI-related plugins
  config = function()
    require("onedark").setup({
      style = "darker", -- Options: dark, darker, cool, deep, warm, warmer
      transparent = false, -- Set to true if you want a transparent background
    })
    require("onedark").load()
  end,
}
