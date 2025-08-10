local runner = require("keymaps.runner.core")
local detection = require("keymaps.runner.project_detection")
local commands = require("keymaps.runner.commands")

vim.keymap.set("n", "<leader>r", function()
  vim.cmd("write")

  local filetype = vim.bo.filetype
  local filename = vim.fn.expand("%:p")
  local root = detection.get_project_root(filename)
  local cwd = vim.fn.getcwd()

  local is_react = root and detection.is_react(root)
  local is_next = root and detection.is_next(root)

  if filetype == "cpp" then
    local out = vim.fn.expand("%:p:r") .. "_out"
    runner.term({ "bash", "-c", "g++ -std=c++17 -Wall -Wextra -o " .. out .. " " .. filename .. " && " .. out })
  elseif filetype == "python" then
    runner.term({ "python", filename })
  elseif filetype == "typescript" or filetype == "javascript" then
    commands.run_js_ts(filetype, filename, root, cwd, is_react, is_next)
  elseif is_react then
    commands.run_react(root)
  elseif is_next then
    commands.run_next(root)
  else
    vim.notify("No runner defined for this filetype", vim.log.levels.WARN)
  end
end, { desc = "Run project by filetype" })

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    require("keymaps.runner.utils").run_background({ "pkill", "-f", "vite" })
    require("keymaps.runner.utils").run_background({ "pkill", "-f", "npm.*run.*dev" })
  end,
})
