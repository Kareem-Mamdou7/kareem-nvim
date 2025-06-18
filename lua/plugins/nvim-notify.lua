return {
  "rcarriga/nvim-notify",
  event = "VeryLazy",
  config = function()
    local notify = require("notify")
    vim.notify = notify

    notify.setup({
      stages = "fade_in_slide_out", -- smooth animations
      background_colour = "#000000", -- works well with Kitty
      timeout = 3000, -- how long notifications stay
      render = "default", -- options: default, minimal, compact
      top_down = true,
    })
  end,
}
