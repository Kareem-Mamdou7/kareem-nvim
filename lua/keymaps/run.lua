vim.keymap.set("n", "<leader>r", function()
  vim.cmd("write")
  local filetype = vim.bo.filetype
  local filename = vim.fn.expand("%:p")
  local output_name = vim.fn.expand("%:p:r") .. "_out"
  local file_ext = vim.fn.expand("%:e")
  local cwd = vim.fn.getcwd()

  local function escape(str)
    return str:gsub(" ", "\\ ")
  end

  local function term(cmd)
    vim.fn.jobstart(cmd, { detach = true })
  end

  local function open_browser()
    vim.fn.jobstart({ "xdg-open", "http://localhost:5173" }, { detach = true })
  end

  local function is_vite_running()
    local result = vim.fn.system("pgrep -f vite")
    return vim.v.shell_error == 0 and result:match("%S") ~= nil
  end

  local function vite_server_logic()
    if is_vite_running() then
      vim.ui.select({ "Open in Browser", "Stop Vite" }, {
        prompt = "Vite is running. Choose an action:",
      }, function(choice)
        if choice == "Open in Browser" then
          open_browser()
        elseif choice == "Stop Vite" then
          vim.fn.jobstart({ "pkill", "-f", "vite" }, { detach = true })
          print("Vite stopped.")
        end
      end)
    else
      vim.fn.jobstart({ "vite" }, { cwd = cwd, detach = true })
      vim.defer_fn(function()
        open_browser()
      end, 1500)
      print("Vite started on http://localhost:5173")
    end
  end

  -- Filetype routing
  if filetype == "cpp" then
    term({
      "bash",
      "-c",
      "g++ -std=c++17 -Wall -Wextra -o " .. escape(output_name) .. " " .. escape(filename) .. " && ./" .. escape(
        output_name
      ),
    })
  elseif filetype == "python" then
    term({ "python", filename })
  elseif file_ext == "ipynb" then
    term({ "jupyter", "notebook", filename })
  elseif
    filetype == "html"
    or filetype == "css"
    or filetype == "javascript"
    or filetype == "typescript"
    or filetype == "vue"
    or filetype == "javascriptreact"
    or filetype == "typescriptreact"
  then
    vite_server_logic()
  elseif filetype == "dart" then
    vim.cmd("FlutterRun")
    vim.defer_fn(function()
      vim.cmd("wincmd p")
    end, 100)
  elseif file_ext == "ino" then
    term({
      "bash",
      "-c",
      "arduino-cli compile --fqbn arduino:avr:uno "
        .. escape(filename)
        .. " && arduino-cli upload -p /dev/ttyACM0 --fqbn arduino:avr:uno "
        .. escape(filename),
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
