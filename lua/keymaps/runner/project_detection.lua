local M = {}

function M.get_project_root(path)
  path = vim.fn.fnamemodify(path or vim.fn.getcwd(), ":p")
  while path ~= "/" do
    if vim.fn.filereadable(path .. "/package.json") == 1 then
      return path
    end
    path = vim.fn.fnamemodify(path, ":h")
  end
  return nil
end

local function has_pkg(root, pkg)
  local package_json = root .. "/package.json"
  if vim.fn.filereadable(package_json) == 0 then
    return false
  end
  local file = io.open(package_json, "r")
  if not file then
    return false
  end
  local content = file:read("*a")
  file:close()
  return content:match('"' .. pkg .. '"%s*:')
end

function M.is_react(root)
  return has_pkg(root, "react") or has_pkg(root, "react-dom")
end

function M.is_next(root)
  return has_pkg(root, "next")
end

return M
