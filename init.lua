-- bootstrap lazy.nvim, LazyVim and your plugins_required
--

require("config.lazy")

vim.cmd("colorscheme vscode")

vim.o.scrolloff = 9
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
