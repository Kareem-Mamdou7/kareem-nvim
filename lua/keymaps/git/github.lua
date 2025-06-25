local map = vim.keymap.set
local opts = { noremap = true, silent = true }

local function is_git_repo()
  return vim.fn.isdirectory(".git") == 1
end

local function run_cmd(cmd)
  local result = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    print("Error running: " .. cmd)
    print(result)
    return nil
  end
  return result
end

map("n", "<leader>gr", function()
  if not is_git_repo() then
    print("Initializing Git repo...")
    if not run_cmd("git init") then
      return
    end
  end

  vim.ui.input({ prompt = "GitHub repo name: " }, function(repo)
    if not repo or repo == "" then
      print("Canceled: No repo name.")
      return
    end

    vim.ui.input({ prompt = "Visibility (1 = Public, 0 = Private): " }, function(visibility)
      local vis_flag = "--public"
      if visibility == "0" then
        vis_flag = "--private"
      end
      if visibility ~= "0" and visibility ~= "1" then
        print("Invalid input. Use 1 or 0.")
        return
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
          print("Canceled: No commit message.")
          return
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

        print("GitHub repo created, pushed, and opened in browser.")
      end)
    end)
  end)
end, { desc = "GitHub: Create + Push Repo (SSH)", unpack(opts) })

map("n", "<leader>gD", function()
  if not is_git_repo() then
    print("Not a git repository.")
    return
  end

  local remote_url = vim.fn.system("git config --get remote.origin.url"):gsub("\n", "")
  if remote_url == "" then
    print("No remote origin set.")
    return
  end

  local repo = remote_url:match("github.com[:/](.-)%.git$")
  if not repo then
    print("Failed to parse remote URL.")
    return
  end

  local confirm = vim.fn.input("Are you sure you want to delete '" .. repo .. "' from GitHub? (yes/NO): ")
  if confirm:lower() ~= "yes" then
    print("Canceled: User did not confirm.")
    return
  end

  local result = vim.fn.systemlist("gh repo delete " .. repo .. " --yes")
  if vim.v.shell_error ~= 0 then
    print("Failed to delete repo:")
    print(table.concat(result, "\n"))
  else
    vim.fn.delete(".git", "rf")
    print("Repo '" .. repo .. "' deleted from GitHub and local .git removed.")
  end
end, { desc = "GitHub: Delete Remote Repo + .git", unpack(opts) })
