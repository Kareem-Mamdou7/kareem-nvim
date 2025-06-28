local map = vim.keymap.set
local opts = { noremap = true, silent = true }

local function is_git_repo()
  return vim.fn.isdirectory(".git") == 1
end

local function run_cmd_safely(cmd)
  local result = vim.fn.systemlist(cmd)
  local success = vim.v.shell_error == 0
  return success, result
end

map("n", "<leader>ga", function()
  if not is_git_repo() then
    print("Not a git repository.")
    return
  end
  vim.fn.system("git add .")
  print("All changes staged.")
end, { desc = "Git: Stage All Files", unpack(opts) })

map("n", "<leader>gA", function()
  if not is_git_repo() then
    print("Not a git repository.")
    return
  end
  local file = vim.fn.expand("%")
  vim.fn.system("git add " .. file)
  print(file .. " staged.")
end, { desc = "Git: Stage Current File", unpack(opts) })

map("n", "<leader>gs", function()
  if not is_git_repo() then
    print("Not a git repository.")
    return
  end
  vim.cmd("terminal git status")
end, { desc = "Git: Status", unpack(opts) })

map("n", "<leader>gc", function()
  if not is_git_repo() then
    print("Not a git repository.")
    return
  end
  vim.ui.input({ prompt = "Commit message: " }, function(msg)
    if not msg or msg == "" then
      print("Commit canceled: No message.")
      return
    end
    local success, result = run_cmd_safely('git commit -m "' .. msg .. '"')
    if success then
      print("Committed with message: " .. msg)
    else
      print("Commit failed:")
      print(table.concat(result, "\n"))
    end
  end)
end, { desc = "Git: Commit with Message", unpack(opts) })

map("n", "<leader>gp", function()
  if not is_git_repo() then
    print("Not a git repository.")
    return
  end
  local success, result = run_cmd_safely("git push")
  if success then
    print("Changes pushed to remote.")
  else
    print("Push failed:")
    print(table.concat(result, "\n"))
  end
end, { desc = "Git: Push", unpack(opts) })

map("n", "<leader>gP", function()
  if not is_git_repo() then
    print("Not a git repository.")
    return
  end
  local success, result = run_cmd_safely("git pull")
  if success then
    print("Changes pulled from remote.")
  else
    print("Pull failed:")
    print(table.concat(result, "\n"))
  end
end, { desc = "Git: Pull", unpack(opts) })

map("n", "<leader>gl", function()
  if not is_git_repo() then
    print("Not a git repository.")
    return
  end
  vim.cmd("vsplit | terminal git log --oneline --graph --decorate --all")
end, { desc = "Git: Log (graph)", unpack(opts) })

map("n", "<leader>gd", function()
  if not is_git_repo() then
    print("Not a git repository.")
    return
  end
  vim.cmd("vsplit | terminal git diff")
end, { desc = "Git: Diff", unpack(opts) })

map("n", "<leader>gL", function()
  if vim.fn.executable("lazygit") == 0 then
    print("lazygit is not installed.")
    return
  end
  vim.cmd("terminal lazygit")
end, { desc = "Git: LazyGit (popup)", unpack(opts) })

vim.keymap.set("n", "<leader>dv", function()
  local dv = require("diffview.lib")
  if next(dv.views) == nil then
    vim.cmd("DiffviewOpen")
  else
    vim.cmd("DiffviewClose")
  end
end, { desc = "Toggle Diffview" })
