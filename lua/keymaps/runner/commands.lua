local M = {}
local utils = require("keymaps.runner.utils")
local vite = require("keymaps.runner.vite")
local detection = require("keymaps.runner.project_detection")
local runner = require("keymaps.runner.core")

function M.run_react(root)
  vim.ui.select({
    "npm run dev",
    "npm run start",
    "npm run build",
    "npm run lint",
  }, { prompt = "React Project: Run command" }, function(choice)
    if not choice then
      return
    end
    utils.ensure_dependencies_installed(root)
    local cmd = choice:match("run (%w+)")
    if cmd == "dev" then
      vite.start_vite_dev_server(root, "5173")
    else
      utils.run_background({ "npm", "run", cmd }, { cwd = root })
    end
  end)
end

function M.run_next(root)
  vim.ui.select({
    "npm run dev",
    "npm run start",
    "npm run build",
  }, { prompt = "Next.js Project: Run command" }, function(choice)
    if not choice then
      return
    end
    utils.ensure_dependencies_installed(root)
    local cmd = choice:match("run (%w+)")
    if cmd == "dev" then
      utils.run_background({ "npm", "run", cmd }, { cwd = root })
      utils.run_background({ "xdg-open", "http://localhost:3000" })
    else
      utils.run_background({ "npm", "run", cmd }, { cwd = root })
    end
  end)
end

function M.run_js_ts(filetype, filename, root, cwd, is_react, is_next)
  local options = { "Run with Node.js" }
  if filetype == "typescript" then
    options[1] = "Run with Node.js (auto compile)"
  end

  if is_next then
    vim.list_extend(options, { "npm run dev", "npm run start", "npm run build" })
  elseif is_react then
    vim.list_extend(options, { "npm run dev", "npm run start", "npm run build", "npm run lint" })
  else
    table.insert(options, "Run index.html with Vite (browser)")
  end

  vim.ui.select(options, { prompt = filetype:upper() .. " File: Choose run option" }, function(choice)
    if not choice then
      return
    end
    if choice:match("Node") then
      if filetype == "typescript" then
        local output_js = filename:gsub("%.ts$", ".js")
        runner.term({
          "bash",
          "-c",
          "tsc " .. vim.fn.shellescape(filename) .. " && node " .. vim.fn.shellescape(output_js),
        })
      else
        runner.term({ "node", filename })
      end
    elseif choice:match("index%.html") then
      vite.start_vite_dev_server(cwd, "5173")
    elseif choice:match("npm run dev") then
      if is_next then
        utils.run_background({ "npm", "run", "dev" }, { cwd = root })
        utils.run_background({ "xdg-open", "http://localhost:3000" })
      else
        vite.start_vite_dev_server(root, "5173")
      end
    else
      local cmd = choice:match("run (%w+)")
      if cmd then
        utils.run_background({ "npm", "run", cmd }, { cwd = root })
      end
    end
  end)
end

return M
