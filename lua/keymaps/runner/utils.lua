local M = {}
local uv = vim.loop

function M.run_background(cmd, opts)
  opts = opts or {}
  opts.cwd = opts.cwd or vim.fn.getcwd()
  opts.detach = true
  vim.fn.jobstart(cmd, opts)
end

function M.ensure_dependencies_installed(root)
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

function M.is_port_open(port, callback)
  local tcp = uv.new_tcp()
  tcp:connect("127.0.0.1", tonumber(port), function(err)
    if err then
      tcp:close()
      callback(false)
    else
      tcp:close()
      callback(true)
    end
  end)
end

return M
