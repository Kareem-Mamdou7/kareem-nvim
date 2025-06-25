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
