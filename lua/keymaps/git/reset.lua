local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Utility: Run shell command and return lines
local function get_lines(cmd)
  local handle = io.popen(cmd)
  if not handle then
    return {}
  end
  local result = handle:read("*a")
  handle:close()
  return vim.split(result or "", "\n", { trimempty = true })
end

-- Utility: Get list of commits with short hash + message
local function get_commit_choices()
  local raw = get_lines("git log --oneline")
  local commits = {}
  for _, line in ipairs(raw) do
    local hash, msg = line:match("^(%S+)%s+(.+)$")
    if hash and msg then
      table.insert(commits, { label = msg, hash = hash })
    end
  end
  return commits
end

-- Git Reset Popup
local function git_reset()
  local commits = get_commit_choices()
  if #commits == 0 then
    print("No commits found.")
    return
  end

  local items = vim.tbl_map(function(c)
    return string.format("[%s] %s", c.hash:sub(1, 7), c.label)
  end, commits)

  vim.ui.select(items, { prompt = "Reset to which commit?" }, function(choice)
    if not choice then
      return
    end

    local selected = vim.tbl_filter(function(c)
      return choice:find(c.hash:sub(1, 7), 1, true)
    end, commits)[1]

    if not selected then
      return
    end

    vim.ui.select({ "Soft Reset", "Hard Reset" }, { prompt = "Choose reset type:" }, function(reset_type)
      if reset_type == "Soft Reset" then
        vim.fn.jobstart({ "git", "reset", "--soft", selected.hash }, { detach = true })
        print("Soft reset to " .. selected.label)
      elseif reset_type == "Hard Reset" then
        vim.fn.jobstart({ "git", "reset", "--hard", selected.hash }, { detach = true })
        print("Hard reset to " .. selected.label)
      end
    end)
  end)
end

-- Git Revert Popup
local function git_revert()
  local commits = get_commit_choices()
  if #commits == 0 then
    print("No commits found.")
    return
  end

  local items = vim.tbl_map(function(c)
    return string.format("[%s] %s", c.hash:sub(1, 7), c.label)
  end, commits)

  vim.ui.select(items, { prompt = "Revert which commit?" }, function(choice)
    if not choice then
      return
    end

    local selected = vim.tbl_filter(function(c)
      return choice:find(c.hash:sub(1, 7), 1, true)
    end, commits)[1]

    if not selected then
      return
    end

    vim.fn.jobstart({ "git", "revert", selected.hash }, {
      detach = true,
      on_exit = function(_, code)
        if code == 0 then
          print("Successfully reverted: " .. selected.label)
        else
          print("Revert failed.")
        end
      end,
    })
  end)
end

-- Keymaps
map("n", "<leader>gR", git_reset, { desc = "Git: Reset to Commit", unpack(opts) })
map("n", "<leader>gV", git_revert, { desc = "Git: Revert Commit", unpack(opts) })
