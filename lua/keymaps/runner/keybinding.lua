local runner = require("keymaps.runner.core")

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
  return content:match('"react"%s*:') or content:match('"react%-dom"%s*:')
end

local function run_background(cmd, opts)
  opts = opts or {}
  opts.cwd = opts.cwd or vim.fn.getcwd()
  opts.detach = true
  vim.fn.jobstart(cmd, opts)
end

local function ensure_dependencies_installed(root)
  if vim.fn.filereadable(root .. "/package.json") == 0 then
    return
  end
  if vim.fn.isdirectory(root .. "/node_modules") == 0 then
    vim.notify("Installing node_modules...", vim.log.levels.INFO)
    local output = vim.fn.system("cd " .. vim.fn.shellescape(root) .. " && npm install")
    if vim.v.shell_error ~= 0 then
      vim.notify("❌ npm install failed:\n" .. output, vim.log.levels.ERROR)
    else
      vim.notify("✅ npm install completed.", vim.log.levels.INFO)
    end
  end
end

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
<head><meta charset="UTF-8" /><title>Index</title></head>
<body><h1>Project Files</h1><ul>
]] .. table.concat(links, "\n") .. [[
</ul></body></html>]]
    local f = io.open(index_path, "w")
    if f then
      f:write(content)
      f:close()
    end
  end
end

local function start_dev_server(root, port)
  port = port or "5173"
  create_default_index_html(root)
  run_background({ "bash", "-l", "-c", "vite --port " .. port }, { cwd = root })
  run_background({ "xdg-open", "http://localhost:" .. port })
  vim.notify("Dev server started on http://localhost:" .. port, vim.log.levels.INFO)
end

vim.keymap.set("n", "<leader>r", function()
  vim.cmd("write")

  local filetype = vim.bo.filetype
  local filename = vim.fn.expand("%:p")
  local root = react_project_root(filename)
  local is_react = root and is_react_project(root)
  local cwd = vim.fn.getcwd()
  local file_ext = vim.fn.expand("%:e")

  if filetype == "cpp" then
    local out = vim.fn.expand("%:p:r") .. "_out"
    runner.term({ "bash", "-c", "g++ -std=c++17 -Wall -Wextra -o " .. out .. " " .. filename .. " && " .. out })
  elseif filetype == "python" then
    runner.term({ "python", filename })
  elseif file_ext == "ipynb" then
    run_background({ "jupyter", "notebook", filename })
    run_background({ "xdg-open", "http://localhost:8888" })
  elseif vim.tbl_contains({ "tsx", "jsx", "javascriptreact", "typescriptreact" }, filetype) then
    vim.ui.select({
      "npm run dev",
      "npm run start",
      "npm run build",
      "npm run lint",
    }, { prompt = "React Project: Run command" }, function(choice)
      if not choice or not root then
        return
      end
      local cmd = choice:match("run (%w+)")
      ensure_dependencies_installed(root)
      if cmd == "dev" then
        run_background({ "npm", "run", cmd, "--", "--port", "5173" }, { cwd = root })
        run_background({ "xdg-open", "http://localhost:5173" })
      else
        run_background({ "npm", "run", cmd }, { cwd = root })
      end
    end)
  elseif vim.tbl_contains({ "typescript", "javascript", "html", "css" }, filetype) then
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
        local cmd = choice:match("run (%w+)")
        ensure_dependencies_installed(root)
        if cmd == "dev" then
          run_background({ "npm", "run", cmd, "--", "--port", "5173" }, { cwd = root })
          run_background({ "xdg-open", "http://localhost:5173" })
        else
          run_background({ "npm", "run", cmd }, { cwd = root })
        end
      end)
    else
      if filetype == "typescript" then
        vim.ui.select({
          "Run with Node.js (auto compile)",
          "Run index.html with Vite (browser)",
        }, { prompt = "TS File: Choose run option" }, function(choice)
          if not choice then
            return
          end
          if choice:match("Node") then
            local output_js = filename:gsub("%.ts$", ".js")
            local cmd = "tsc " .. vim.fn.shellescape(filename) .. " && node " .. vim.fn.shellescape(output_js)
            runner.term({ "bash", "-c", cmd })
          else
            start_dev_server(cwd, "5173")
          end
        end)
      elseif filetype == "javascript" then
        vim.ui.select({
          "Run with Node.js",
          "Run index.html with Vite (browser)",
        }, { prompt = "JS File: Choose run option" }, function(choice)
          if not choice then
            return
          end
          if choice:match("Node") then
            runner.term({ "node", filename })
          else
            start_dev_server(cwd, "5173")
          end
        end)
      else
        start_dev_server(cwd, "5173")
      end
    end
  else
    vim.notify("No runner defined for this filetype", vim.log.levels.WARN)
  end
end, { desc = "Run project by filetype" })

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    run_background({ "pkill", "-f", "vite" })
    run_background({ "pkill", "-f", "npm.*run.*dev" })
  end,
})
