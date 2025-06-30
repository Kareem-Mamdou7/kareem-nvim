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
    vim.cmd('split | terminal bash -c "' .. cmd .. '"')
    vim.cmd("normal! G")
  end

  local function open_browser()
    vim.fn.jobstart({ "xdg-open", "http://127.0.0.1:5500" }, { detach = true })
  end

  local function check_live_server_sync()
    local result = vim.fn.system("pgrep -f live-server")
    local is_running = vim.v.shell_error == 0 and result:match("%S") ~= nil
    return is_running
  end

  local function live_server_logic()
    local is_running = check_live_server_sync()

    if is_running then
      vim.ui.select({ "Open in Browser", "Stop Live Server" }, {
        prompt = "Live Server is running. Choose an action:",
      }, function(choice)
        if choice == "Open in Browser" then
          open_browser()
        elseif choice == "Stop Live Server" then
          vim.fn.jobstart({ "pkill", "-f", "live-server" }, { detach = true })
          print("Live Server stopped.")
        end
      end)
    else
      vim.fn.jobstart({
        "live-server",
        "--port=5500",
        "--no-browser",
        "--ignore=node_modules,.git,dist,build,*.zip,*.svg,*.psd",
        cwd,
      }, { cwd = cwd, detach = true })
      vim.defer_fn(function()
        open_browser()
      end, 500)
      print("Live Server started on http://127.0.0.1:5500")
    end
  end

  if filetype == "cpp" then
    term(
      "g++ -std=c++17 -Wall -Wextra -o "
        .. escape(output_name)
        .. " "
        .. escape(filename)
        .. " && ./"
        .. escape(output_name)
    )
  elseif filetype == "python" then
    term("python " .. escape(filename))
  elseif file_ext == "ipynb" then
    term("jupyter notebook " .. escape(filename))
  elseif filetype == "html" or filetype == "css" then
    live_server_logic()
  elseif filetype == "javascript" then
    vim.ui.select({ "Browser (Live Server)", "Terminal (Node)" }, {
      prompt = "Run JavaScript in:",
    }, function(choice)
      if choice == "Browser (Live Server)" then
        live_server_logic()
      elseif choice == "Terminal (Node)" then
        term("node " .. escape(filename))
      end
    end)
  elseif filetype == "dart" then
    vim.cmd("FlutterRun")
    vim.defer_fn(function()
      vim.cmd("wincmd p")
    end, 100)
  elseif file_ext == "ino" then
    term(
      "arduino-cli compile --fqbn arduino:avr:uno "
        .. escape(filename)
        .. " && arduino-cli upload -p /dev/ttyACM0 --fqbn arduino:avr:uno "
        .. escape(filename)
    )
  else
    vim.notify("No run command for this filetype", vim.log.levels.WARN)
  end
end, { desc = "Run file based on type" })

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    vim.fn.jobstart({ "pkill", "-f", "live-server" }, { detach = true })
  end,
})
