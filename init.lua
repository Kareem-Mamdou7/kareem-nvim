-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

if not vim.g.vscode then
  -- Only load colorscheme when not inside VSCode
  vim.cmd("colorscheme vscode")
  -- vim.cmd("colorscheme darkplus")
  -- vim.cmd("colorscheme catppuccin")

  -- Any UI-specific config
  -- require("statusline").setup()
  -- require("lualine").setup()
end

vim.opt.termguicolors = true

require("lspconfig").arduino_language_server.setup({
  cmd = {
    "arduino-language-server",
    "--cli",
    "arduino-cli",
    "--fqbn",
    "arduino:avr:uno", -- Replace with your board's FQBN
    "--cli-config",
    "/home/kareem/.arduino15/arduino-cli.yaml",
  },
})

vim.api.nvim_create_autocmd("BufReadPost", {
  pattern = { "*.jsx", "*.tsx" },
  callback = function()
    local filename = vim.fn.expand("%:t:r")
    local line_count = vim.api.nvim_buf_line_count(0)
    local first_line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]

    -- Only apply if file is empty and newly created (no lines except one empty line)
    if line_count == 1 and (first_line == nil or first_line == "") then
      local template = {
        'import { useState, useEffect } from "react";',
        "",
        string.format("function %s() {", filename),
        "  return (",
        "    <>",
        "",
        "    </>",
        "  );",
        "}",
        "",
        string.format("export default %s;", filename),
      }

      vim.api.nvim_buf_set_lines(0, 0, -1, false, template)
      vim.cmd("normal! G") -- Move cursor to end
    end
  end,
})
