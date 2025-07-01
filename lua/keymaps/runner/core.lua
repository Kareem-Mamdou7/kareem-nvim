local M = {}

local escape = function(str)
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

local function create_index_if_missing()
  local cwd = vim.fn.getcwd()
  local index_path = cwd .. "/index.html"

  if vim.fn.filereadable(index_path) == 0 then
    local html_files = vim.fn.glob("*.html", false, true)
    local lines = {
      "<!DOCTYPE html>",
      "<html>",
      "  <head>",
      '    <meta charset="UTF-8">',
      "    <title>Auto Index</title>",
      "  </head>",
      "  <body>",
      "    <h1>Index of HTML Files</h1>",
      "    <ul>",
    }

    for _, file in ipairs(html_files) do
      table.insert(lines, string.format('      <li><a href="%s">%s</a></li>', file, file))
    end

    table.insert(lines, "    </ul>")
    table.insert(lines, "  </body>")
    table.insert(lines, "</html>")

    vim.fn.writefile(lines, index_path)
    print("Auto-generated index.html")
  end
end

function M.vite_server_logic()
  local cwd = vim.fn.getcwd()
  create_index_if_missing()

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
    vim.defer_fn(open_browser, 1500)
    print("Vite started on http://localhost:5173")
  end
end

function M.term(cmd)
  term(cmd)
end

function M.escape(str)
  return escape(str)
end

return M
