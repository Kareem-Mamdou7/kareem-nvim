return {
  "NvChad/nvim-colorizer.lua",
  event = "VeryLazy",
  config = function()
    require("colorizer").setup({
      filetypes = {
        "*", -- Highlight all files, but customize below
      },
      user_default_options = {
        RGB = true, -- #RGB hex codes
        RRGGBB = true, -- #RRGGBB hex codes
        names = true, -- "red", "blue", etc
        RRGGBBAA = true, -- #RRGGBBAA hex codes
        rgb_fn = true, -- rgb() and rgba()
        hsl_fn = true, -- hsl() and hsla()
        css = true, -- Enable all css features: rgb_fn, hsl_fn, names, RGB, RRGGBB
        css_fn = true, -- Enable all CSS *functions*
        -- Available modes: foreground, background, virtualtext
        mode = "background",
      },
    })

    -- You can also set it to auto attach on certain filetypes
    vim.cmd([[ColorizerAttachToBuffer]])
  end,
}
