local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Stage all files
map("n", "<leader>ga", function()
  vim.cmd("!git add .")
  print("All changes staged.")
end, { desc = "Git: Stage All Files", unpack(opts) })

-- Stage current file
map("n", "<leader>gA", function()
  local file = vim.fn.expand("%")
  vim.cmd("!git add " .. file)
  print(file .. " staged.")
end, { desc = "Git: Stage Current File", unpack(opts) })

-- Git status in terminal
map("n", "<leader>gs", "<cmd>terminal git status<CR>", { desc = "Git: Status", unpack(opts) })

-- Commit with user input message
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

-- Push to remote
map("n", "<leader>gp", function()
  vim.cmd("!git push")
  print("Changes pushed to remote.")
end, { desc = "Git: Push", unpack(opts) })

-- Create GitHub repo using GH CLI
map("n", "<leader>gr", function()
  local function run_cmd(cmd)
    local result = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 then
      print("Error running: " .. cmd)
      print(result)
      return nil
    end
    return result
  end

  if vim.fn.isdirectory(".git") == 0 then
    print("Initializing git repo...")
    if not run_cmd("git init") then
      return
    end
  end

  vim.ui.input({ prompt = "GitHub repo name: " }, function(repo)
    if not repo or #repo == 0 then
      return print("Canceled: No repo name.")
    end

    vim.ui.input({ prompt = "Visibility (1 = Public, 0 = Private): " }, function(visibility)
      local vis_flag = (visibility == "0") and "--private" or "--public"
      if visibility ~= "0" and visibility ~= "1" then
        return print("Invalid input. Use 1 or 0.")
      end

      local remotes = vim.fn.systemlist("git remote")
      if vim.tbl_contains(remotes, "origin") then
        if not run_cmd("git remote remove origin") then
          return
        end
      end

      local readme_path = "README.md"
      local readme_content = "# " .. repo .. "\n\nCreated via Neovim automation."
      vim.fn.writefile(vim.split(readme_content, "\n"), readme_path)

      vim.ui.input({ prompt = "Commit message: " }, function(commit_msg)
        if not commit_msg or #commit_msg == 0 then
          return print("Canceled: No commit message.")
        end

        if not run_cmd("git add .") then
          return
        end
        if not run_cmd('git commit -m "' .. commit_msg .. '"') then
          return
        end
        if not run_cmd("git branch -M main") then
          return
        end

        local create_cmd = string.format('gh repo create "%s" %s --source=. --remote=origin --push', repo, vis_flag)
        if not run_cmd(create_cmd) then
          return
        end

        local open_cmd = string.format('gh repo view "%s" --web', repo)
        if not run_cmd(open_cmd) then
          return
        end

        print("Repo created, pushed, and opened in browser.")
      end)
    end)
  end)
end, { desc = "GitHub: Create + Push Repo (SSH)", unpack(opts) })

-- Delete GitHub repo and remove local .git
map("n", "<leader>gD", function()
  local remote_url = vim.fn.system("git config --get remote.origin.url"):gsub("\n", "")
  if remote_url == "" then
    return print("No remote origin set.")
  end

  local repo = remote_url:match("github.com[:/](.-)%.git$")
  if not repo then
    return print("Failed to parse remote URL.")
  end

  local confirm = vim.fn.input("Are you sure you want to delete '" .. repo .. "' from GitHub? (yes/NO): ")
  if confirm:lower() ~= "yes" then
    return print("Canceled: User did not confirm.")
  end

  local result = vim.fn.systemlist("gh repo delete " .. repo .. " --yes")
  if vim.v.shell_error ~= 0 then
    print("Failed to delete repo. Reason:")
    print(table.concat(result, "\n"))
  else
    vim.fn.delete(".git", "rf")
    print("Repo '" .. repo .. "' deleted from GitHub and local .git removed.")
  end
end, { desc = "GitHub: Delete Remote Repo + .git", unpack(opts) })
