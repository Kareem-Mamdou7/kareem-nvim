local M = {}
local utils = require("keymaps.runner.utils")

function M.create_default_index_html(root)
  local index_path = root .. "/index.html"
  if vim.fn.filereadable(index_path) == 0 then
    local html_files = vim.fn.glob(root .. "/*.html", false, true)
    local links = {}
    for _, file in ipairs(html_files) do
      table.insert(
        links,
        '<li><a href="' .. vim.fn.fnamemodify(file, ":t") .. '">' .. vim.fn.fnamemodify(file, ":t") .. "</a></li>"
      )
    end
    local f = io.open(index_path, "w")
    if f then
      f:write("<!DOCTYPE html><html><body><ul>" .. table.concat(links, "\n") .. "</ul></body></html>")
      f:close()
    end
  end
end

function M.start_vite_dev_server(root, port)
  port = port or "5173"
  M.create_default_index_html(root)
  utils.is_port_open(port, function(open)
    if open then
      vim.notify("Vite already running → opening browser", vim.log.levels.INFO)
      utils.run_background({ "xdg-open", "http://localhost:" .. port })
    else
      vim.notify("Starting Vite dev server...", vim.log.levels.INFO)
      utils.run_background({ "bash", "-l", "-c", "vite --port " .. port }, { cwd = root })
      utils.run_background({ "xdg-open", "http://localhost:" .. port })
    end
  end)
end

return M
