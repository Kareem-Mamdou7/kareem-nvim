local runner = require("keymaps.runner.core")

local react_server_running = false

local function react_project_root()
  local root = vim.fn.findfile("package.json", ".;")
  if root ~= "" then
    return vim.fn.fnamemodify(root, ":h")
  end
  return nil
end

local function run_background(cmd, opts)
  opts = opts or {}
  opts.cwd = opts.cwd or vim.fn.getcwd()
  opts.detach = true
  vim.fn.jobstart(cmd, opts)
end

local function start_dev_server(root, port)
  port = port or "5173"
  local cmd = "vite --port " .. port
  run_background({ "bash", "-l", "-c", cmd }, { cwd = root })
  react_server_running = true
  run_background({ "xdg-open", "http://localhost:" .. port })
  vim.notify("Dev server started on http://localhost:" .. port, vim.log.levels.INFO)
end

vim.keymap.set("n", "<leader>r", function()
  vim.cmd("write")

  local filetype = vim.bo.filetype
  local filename = vim.fn.expand("%:p")
  local output_name = vim.fn.expand("%:p:r") .. "_out"
  local file_ext = vim.fn.expand("%:e")
  local cwd = vim.fn.getcwd()
  local root = react_project_root()

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
    run_background({ "jupyter", "notebook", filename })
    run_background({ "xdg-open", "http://localhost:8888" })
  elseif vim.tbl_contains({ "javascriptreact", "typescriptreact", "jsx", "tsx" }, filetype) then
    vim.ui.select({
      "npm run dev",
      "npm run start",
      "npm run build",
      "npm run lint",
    }, { prompt = "Run React command:" }, function(choice)
      if not choice then
        return
      end

      local command = choice:match("run (%w+)")
      if choice == "npm run dev" then
        run_background({ "npm", "run", command, "--", "--port", "5173" }, { cwd = root })
        run_background({ "xdg-open", "http://localhost:5173" })
        react_server_running = true
      else
        run_background({ "npm", "run", command }, { cwd = root })
      end
    end)
  elseif filetype == "javascript" then
    vim.ui.select({
      "Run with Vite (open index.html)",
      "Run with Node.js in terminal",
    }, { prompt = "JavaScript options:" }, function(js_choice)
      if js_choice == "Run with Vite (open index.html)" then
        local index_path = cwd .. "/index.html"
        if vim.fn.filereadable(index_path) == 0 then
          vim.notify("No index.html found in current directory", vim.log.levels.WARN)
          return
        end

        if react_server_running then
          vim.ui.select(
            { "Open browser tab", "Kill dev server" },
            { prompt = "Dev server is already running" },
            function(choice)
              if choice == "Open browser tab" then
                run_background({ "xdg-open", "http://localhost:5173" })
              elseif choice == "Kill dev server" then
                run_background({ "pkill", "-f", "vite" })
                react_server_running = false
                vim.notify("Dev server killed", vim.log.levels.INFO)
              end
            end
          )
        else
          start_dev_server(cwd, "5173")
        end
      elseif js_choice == "Run with Node.js in terminal" then
        runner.term({ "node", filename })
      end
    end)
  elseif vim.tbl_contains({ "html", "css", "vue" }, filetype) then
    local index_path = cwd .. "/index.html"
    if vim.fn.filereadable(index_path) == 0 then
      vim.notify("No index.html found in current directory", vim.log.levels.WARN)
      return
    end

    if react_server_running then
      vim.ui.select(
        { "Open browser tab", "Kill dev server" },
        { prompt = "Dev server is already running" },
        function(choice)
          if choice == "Open browser tab" then
            run_background({ "xdg-open", "http://localhost:5173" })
          elseif choice == "Kill dev server" then
            run_background({ "pkill", "-f", "vite" })
            react_server_running = false
            vim.notify("Dev server killed", vim.log.levels.INFO)
          end
        end
      )
    else
      start_dev_server(cwd, "5173")
    end
  elseif filetype == "dart" then
    vim.cmd("FlutterRun")
    vim.defer_fn(function()
      vim.cmd("wincmd p")
    end, 100)
    run_background({ "xdg-open", "http://localhost:8000" })
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
end, { desc = "Run project based on file type" })

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    run_background({ "pkill", "-f", "vite" })
    run_background({ "pkill", "-f", "npm.*run.*dev" })
  end,
})
