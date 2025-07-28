local runner = require("keymaps.runner.core")

local react_server_running = false

-- Find project root by locating package.json
local function react_project_root(path)
  path = vim.fn.fnamemodify(path or vim.fn.getcwd(), ":p")
  while path ~= "/" do
    if vim.fn.filereadable(path .. "/package.json") == 1 then
      return path
    end
    path = vim.fn.fnamemodify(path, ":h")
  end
  return nil
end

-- Check if project is React-based
local function is_react_project(path)
  local package_json = path .. "/package.json"
  if vim.fn.filereadable(package_json) == 0 then
    return false
  end
  local file = io.open(package_json, "r")
  if not file then
    return false
  end
  local content = file:read("*a")
  file:close()
  return content:match('"react"%s*:') or content:match('"react%-dom"%s*:') or content:match('"vite"%s*:') ~= nil
end

-- Run background job detached
local function run_background(cmd, opts)
  opts = opts or {}
  opts.cwd = opts.cwd or vim.fn.getcwd()
  opts.detach = true
  vim.fn.jobstart(cmd, opts)
end

-- Auto npm install
local function ensure_dependencies_installed(root)
  local package_json = root .. "/package.json"
  if vim.fn.filereadable(package_json) == 0 then
    return
  end
  local node_modules_path = root .. "/node_modules"
  if vim.fn.isdirectory(node_modules_path) == 0 then
    vim.notify("node_modules missing. Running npm install...", vim.log.levels.INFO)
    local output = vim.fn.system("cd " .. vim.fn.shellescape(root) .. " && npm install")
    if vim.v.shell_error ~= 0 then
      vim.notify("❌ npm install failed:\n" .. output, vim.log.levels.ERROR)
    else
      vim.notify("✅ npm install completed.", vim.log.levels.INFO)
    end
  end
end

-- Generate index.html for plain Vite
local function create_default_index_html(root)
  local index_path = root .. "/index.html"
  if vim.fn.filereadable(index_path) == 0 then
    local html_files = vim.fn.glob(root .. "/*.html", false, true)
    local links = {}
    for _, file in ipairs(html_files) do
      local name = vim.fn.fnamemodify(file, ":t")
      table.insert(links, '<li><a href="' .. name .. '">' .. name .. "</a></li>")
    end
    local content = [[
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8" />
    <title>Index</title>
  </head>
  <body>
    <h1>Project Files</h1>
    <ul>
]] .. table.concat(links, "\n") .. [[
    </ul>
  </body>
</html>]]

    local file = io.open(index_path, "w")
    if file then
      file:write(content)
      file:close()
      vim.notify("📝 index.html was created automatically.", vim.log.levels.INFO)
    end
  end
end

-- Start vite server
local function start_dev_server(root, port)
  port = port or "5173"
  create_default_index_html(root)
  local cmd = "vite --port " .. port
  run_background({ "bash", "-l", "-c", cmd }, { cwd = root })
  react_server_running = true
  run_background({ "xdg-open", "http://localhost:" .. port })
  vim.notify("Dev server started on http://localhost:" .. port, vim.log.levels.INFO)
end

-- Main runner
vim.keymap.set("n", "<leader>r", function()
  vim.cmd("write")

  local filetype = vim.bo.filetype
  local filename = vim.fn.expand("%:p")
  local output_name = vim.fn.expand("%:p:r") .. "_out"
  local file_ext = vim.fn.expand("%:e")
  local cwd = vim.fn.getcwd()
  local root = react_project_root(filename)
  local is_react = root and is_react_project(root)

  if filetype == "cpp" then
    runner.term({
      "bash",
      "-c",
      "g++ -std=c++17 -Wall -Wextra -o "
        .. runner.escape(output_name)
        .. " "
        .. runner.escape(filename)
        .. " && "
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
      if not choice or not root then
        return
      end
      local command = choice:match("run (%w+)")
      ensure_dependencies_installed(root)
      if command == "dev" then
        run_background({ "npm", "run", command, "--", "--port", "5173" }, { cwd = root })
        run_background({ "xdg-open", "http://localhost:5173" })
        react_server_running = true
      else
        run_background({ "npm", "run", command }, { cwd = root })
      end
    end)
  elseif vim.tbl_contains({ "javascript", "html", "css" }, filetype) then
    if is_react then
      vim.ui.select({
        "npm run dev",
        "npm run start",
        "npm run build",
        "npm run lint",
      }, { prompt = "React Project: Run command" }, function(choice)
        if not choice or not root then
          return
        end
        local command = choice:match("run (%w+)")
        ensure_dependencies_installed(root)
        if command == "dev" then
          run_background({ "npm", "run", command, "--", "--port", "5173" }, { cwd = root })
          run_background({ "xdg-open", "http://localhost:5173" })
          react_server_running = true
        else
          run_background({ "npm", "run", command }, { cwd = root })
        end
      end)
    else
      if filetype == "javascript" then
        vim.ui.select({
          "Run JS with Node.js (terminal)",
          "Run index.html with Vite (browser)",
        }, { prompt = "JS File: Choose run option" }, function(choice)
          if not choice then
            return
          end
          if choice:match("Node") then
            runner.term({ "node", filename })
          elseif choice:match("Vite") then
            start_dev_server(cwd, "5173")
          end
        end)
      else
        start_dev_server(cwd, "5173")
      end
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

-- Kill vite and npm dev servers when Neovim exits
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    run_background({ "pkill", "-f", "vite" })
    run_background({ "pkill", "-f", "npm.*run.*dev" })
  end,
})
