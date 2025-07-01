local runner = require("keymaps.runner.core")

vim.keymap.set("n", "<leader>r", function()
  vim.cmd("write")

  local filetype = vim.bo.filetype
  local filename = vim.fn.expand("%:p")
  local output_name = vim.fn.expand("%:p:r") .. "_out"
  local file_ext = vim.fn.expand("%:e")
  local cwd = vim.fn.getcwd()

  if filetype == "cpp" then
    runner.term({
      "bash",
      "-c",
      "g++ -std=c++17 -Wall -Wextra -o "
        .. runner.escape(output_name)
        .. " "
        .. runner.escape(filename)
        .. " && ./"
        .. runner.escape(output_name),
    })
  elseif filetype == "python" then
    runner.term({ "python", filename })
  elseif file_ext == "ipynb" then
    runner.term({ "jupyter", "notebook", filename })
  elseif
    vim.tbl_contains({
      "html",
      "css",
      "javascript",
      "typescript",
      "vue",
      "javascriptreact",
      "typescriptreact",
    }, filetype)
  then
    runner.vite_server_logic()
  elseif filetype == "dart" then
    vim.cmd("FlutterRun")
    vim.defer_fn(function()
      vim.cmd("wincmd p")
    end, 100)
  elseif file_ext == "ino" then
    runner.term({
      "bash",
      "-c",
      "arduino-cli compile --fqbn arduino:avr:uno "
        .. runner.escape(filename)
        .. " && arduino-cli upload -p /dev/ttyACM0 --fqbn arduino:avr:uno "
        .. runner.escape(filename),
    })
  else
    vim.notify("No run command for this filetype", vim.log.levels.WARN)
  end
end, { desc = "Run file based on type" })

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    vim.fn.jobstart({ "pkill", "-f", "vite" }, { detach = true })
  end,
})
