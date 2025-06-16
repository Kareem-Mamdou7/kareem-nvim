-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- vim.cmd("colorscheme darkplus")
-- vim.cmd("colorscheme catppuccin")
vim.cmd("colorscheme vscode")

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
