local map = vim.keymap.set

map("n", "<leader>r", function()
  vim.cmd("write") -- Save current file

  local filetype = vim.bo.filetype
  local filename = vim.fn.expand("%:p")
  local output_name = vim.fn.expand("%:p:r") .. "_out"
  local file_ext = vim.fn.expand("%:e")
  local cwd = vim.fn.getcwd()

  local function escape_spaces(name)
    return name:gsub(" ", "\\ ")
  end

  local function run_in_terminal(cmd)
    vim.cmd('split | terminal bash -c "' .. cmd .. '"')
    vim.cmd("normal! G")
  end

  if filetype == "cpp" then
    run_in_terminal(
      "g++ -std=c++17 -Wall -Wextra -o "
        .. escape_spaces(output_name)
        .. " "
        .. escape_spaces(filename)
        .. " && "
        .. escape_spaces(output_name)
    )
  elseif filetype == "python" then
    run_in_terminal("python " .. escape_spaces(filename))
  elseif file_ext == "ipynb" then
    run_in_terminal("jupyter notebook " .. escape_spaces(filename))
  elseif filetype == "html" or filetype == "css" then
    -- Serve the entire working directory, not just the file
    vim.cmd("LiveServerStart " .. cwd)
  elseif filetype == "javascript" then
    vim.ui.select({ "Open in Live Server", "Run in Terminal" }, {
      prompt = "JavaScript Run Mode:",
    }, function(choice)
      if choice == "Run in Terminal" then
        run_in_terminal("node " .. escape_spaces(filename))
      elseif choice == "Open in Live Server" then
        vim.cmd("LiveServerStart " .. cwd)
      end
    end)
  elseif filetype == "dart" then
    vim.cmd("FlutterRun")
    vim.defer_fn(function()
      vim.cmd("wincmd p") -- Return to previous window
    end, 100)
  elseif file_ext == "ino" then
    local fqbn = "arduino:avr:uno"
    local port = "/dev/ttyACM0"
    run_in_terminal(
      "arduino-cli compile --fqbn "
        .. fqbn
        .. " "
        .. escape_spaces(filename)
        .. " && arduino-cli upload -p "
        .. port
        .. " --fqbn "
        .. fqbn
        .. " "
        .. escape_spaces(filename)
    )
  else
    vim.notify("No run command set for this filetype", vim.log.levels.WARN)
  end
end, { desc = "Run file based on type" })
