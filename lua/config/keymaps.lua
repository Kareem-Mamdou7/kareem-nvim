-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "<leader>cx", "<cmd>CellularAutomaton make_it_rain<CR>")

vim.keymap.set("n", "<leader>r", function()
  vim.cmd("write")

  local filetype = vim.bo.filetype
  local filename = vim.fn.expand("%:p")
  local output_name = vim.fn.expand("%:p:r") .. "_out"
  local file_ext = vim.fn.expand("%:e")

  local function escape_spaces(name)
    return name:gsub(" ", "\\ ")
  end

  local function run_in_terminal(cmd)
    vim.cmd("split | terminal bash -c " .. '"' .. cmd .. '"')
    vim.cmd("normal! G")
  end

  if filetype == "cpp" then
    run_in_terminal(
      "g++ -std=c++17 -Wall -Wextra -o "
        .. escape_spaces(output_name)
        .. " "
        .. escape_spaces(filename)
        .. " && "
        .. escape_spaces(output_name)
    )
  elseif filetype == "python" then
    run_in_terminal("python " .. escape_spaces(filename))
  elseif file_ext == "ipynb" then
    run_in_terminal("jupyter notebook " .. escape_spaces(filename))
  elseif filetype == "html" or filetype == "css" then
    vim.cmd("LiveServerStart")
  elseif filetype == "javascript" then
    run_in_terminal("node " .. escape_spaces(filename))
  elseif filetype == "dart" then
    vim.cmd("FlutterRun")
    vim.defer_fn(function()
      vim.cmd("wincmd p")
    end, 100)
  elseif file_ext == "ino" then
    -- Customize this part with your actual board info and port
    local fqbn = "arduino:avr:uno"
    local port = "/dev/ttyACM0"
    run_in_terminal(
      "arduino-cli compile --fqbn "
        .. fqbn
        .. " "
        .. escape_spaces(filename)
        .. " && arduino-cli upload -p "
        .. port
        .. " --fqbn "
        .. fqbn
        .. " "
        .. escape_spaces(filename)
    )
  else
    vim.notify("No run command set for this filetype", vim.log.levels.WARN)
  end
end, { desc = "Run file based on type" })

-- Map another key to toggle Dev Log manually
vim.keymap.set("n", "<leader>fd", function()
  vim.cmd("FlutterDevTools")
end, { desc = "Toggle Flutter Dev Log" })

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Stage all changes (git add .)
map("n", "<leader>ga", function()
  vim.cmd("!git add .")
  print("All changes staged.")
end, { desc = "Git: Stage All Files", unpack(opts) })

-- Stage current file only
map("n", "<leader>gA", function()
  local file = vim.fn.expand("%")
  vim.cmd("!git add " .. file)
  print(file .. " staged.")
end, { desc = "Git: Stage Current File", unpack(opts) })

-- Git status in terminal
map("n", "<leader>gs", function()
  vim.cmd("terminal git status")
end, { desc = "Git: Status", unpack(opts) })

-- Git commit with message prompt
map("n", "<leader>gc", function()
  vim.ui.input({ prompt = "Commit message: " }, function(msg)
    if msg and #msg > 0 then
      vim.cmd("!git commit -m '" .. msg .. "'")
      print("Committed with message: " .. msg)
    else
      print("Commit canceled: No message given.")
    end
  end)
end, { desc = "Git: Commit with Message", unpack(opts) })

-- Git push
map("n", "<leader>gp", function()
  vim.cmd("!git push")
  print("Changes pushed to remote.")
end, { desc = "Git: Push", unpack(opts) })

-- Create GitHub repo via gh CLI with prompts
map("n", "<leader>gr", function()
  if vim.fn.isdirectory(".git") == 0 then
    print("No git repo found, initializing...")
    vim.fn.system("git init")
  end

  vim.ui.input({ prompt = "GitHub repo name: " }, function(repo)
    if not repo or #repo == 0 then
      print("Canceled: No repo name.")
      return
    end

    vim.ui.input({ prompt = "Visibility (1 = Public, 0 = Private): " }, function(visibility)
      local vis_flag = "--public"
      if visibility == "0" then
        vis_flag = "--private"
      elseif visibility ~= "1" then
        print("Invalid input. Use 1 or 0.")
        return
      end

      -- Remove origin if exists
      local remotes = vim.fn.systemlist("git remote")
      if vim.tbl_contains(remotes, "origin") then
        vim.fn.system("git remote remove origin")
      end

      -- Create GitHub repo
      local create_cmd = string.format('gh repo create "%s" %s --source=. --remote=origin', repo, vis_flag)
      vim.fn.system(create_cmd)
      print("Repo created.")

      -- Add SSH remote
      local ssh_url = "git@github.com:Kareem-Mamdou7/" .. repo .. ".git"
      vim.fn.system("git remote add origin " .. ssh_url)
      print("Remote added: " .. ssh_url)

      -- Prompt for commit message
      vim.ui.input({ prompt = "Commit message: " }, function(commit_msg)
        if not commit_msg or #commit_msg == 0 then
          print("Commit canceled: No message.")
          return
        end

        vim.fn.system("git add .")
        vim.fn.system('git commit -m "' .. commit_msg .. '"')
        vim.fn.system("git branch -M main")
        vim.fn.system("git push -u origin main")
        print("Repo pushed to GitHub.")
      end)
    end)
  end)
end, { desc = "GitHub: Create + Push Repo (SSH)", unpack(opts) })

vim.keymap.set("n", "<leader>gD", function()
  local remote_url = vim.fn.system("git config --get remote.origin.url"):gsub("\n", "")
  if remote_url == "" then
    print("❌ No remote origin set.")
    return
  end

  -- Extract repo name
  local repo = remote_url:match("github.com[:/](.-)%.git$")
  if not repo then
    print("❌ Failed to parse remote URL.")
    return
  end

  local confirm = vim.fn.input("Are you sure you want to delete '" .. repo .. "' from GitHub? (yes/NO): ")
  if confirm:lower() ~= "yes" then
    print("Canceled: User did not confirm.")
    return
  end

  local cmd = "gh repo delete " .. repo .. " --yes"
  local result = vim.fn.systemlist(cmd)

  if vim.v.shell_error ~= 0 then
    print("❌ Failed to delete repo. Reason:")
    print(table.concat(result, "\n"))
  else
    print("✅ Repo '" .. repo .. "' deleted from GitHub.")
  end
end, { desc = "GitHub: Delete Current Remote Repo" })
