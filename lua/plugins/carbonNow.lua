return {
  "ellisonleao/carbon-now.nvim",
  cmd = "CarbonNow",
  config = function()
    require("carbon-now").setup({
      open_cmd = "xdg-open",
      options = {
        theme = "seti", -- dark but soft
        font_family = "Fira Code",
        font_size = "16px",
        line_height = "140%",
        padding_vertical = "36px",
        padding_horizontal = "44px",
        bg = "rgba(48, 54, 61, 1)", -- custom dark-gray (not black)
        drop_shadow = true,
        drop_shadow_blur = "48px",
        drop_shadow_offset_y = "20px",
        line_numbers = true,
        window_theme = "boxy", -- rounded corners
        window_controls = true,
        watermark = false,
        export_size = "2x",
        titlebar = "Shared from Neovim",
      },
    })
  end,
}
